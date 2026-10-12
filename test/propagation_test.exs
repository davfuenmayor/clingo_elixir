defmodule Clingo.PropagationTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "propagator construction constraints, watched propagation, undo and decisions" do
    Clingo.with_session(fn s ->
      owner = self()

      init =
        field_callback(s, "clingo_propagator_t", :init, fn init, _ ->
          literal = out(s, :propagate_init_add_literal, [init, true], "clingo_literal_t")
          clause = Clingo.array(s, "clingo_literal_t", [literal])
          assert out(s, :propagate_init_add_clause, [init, clause, 1], "bool")
          weights = Clingo.array(s, "clingo_weighted_literal_t", [%{literal: literal, weight: 1}])

          assert out(
                   s,
                   :propagate_init_add_weight_constraint,
                   [init, literal, weights, 1, 1, 0, false],
                   "bool"
                 )

          assert A.propagate_init_add_minimize(s, init, literal, 0, 0)
          atoms = out(s, :propagate_init_symbolic_atoms, [init], "clingo_symbolic_atoms_t*")

          it =
            out(
              s,
              :symbolic_atoms_find,
              [atoms, symbol(s, "a")],
              "clingo_symbolic_atom_iterator_t"
            )

          program = out(s, :symbolic_atoms_literal, [atoms, it], "clingo_literal_t")
          solver = out(s, :propagate_init_solver_literal, [init, program], "clingo_literal_t")
          assert A.propagate_init_add_watch(s, init, solver)
          assert A.propagate_init_add_watch(s, init, -solver)
          A.propagate_init_set_check_mode(s, init, 3)
          A.propagate_init_set_undo_mode(s, init, 1)
          true
        end)

      propagate =
        field_callback(s, "clingo_propagator_t", :propagate, fn control, changes, count, _ ->
          assert count > 0
          [lit | _] = Clingo.read_array(s, changes, count)
          assert A.propagate_control_has_watch(s, control, lit)
          assert A.propagate_control_add_watch(s, control, lit)
          A.propagate_control_remove_watch(s, control, lit)
          refute A.propagate_control_has_watch(s, control, lit)
          assert A.propagate_control_add_watch(s, control, lit)
          added = out(s, :propagate_control_add_literal, [control], "clingo_literal_t")
          assert is_integer(added)
          clause = Clingo.array(s, "clingo_literal_t", [lit, -lit])
          assert out(s, :propagate_control_add_clause, [control, clause, 2, 0], "bool")
          assert out(s, :propagate_control_propagate, [control], "bool")
          assignment = A.propagate_control_assignment(s, control)
          level = A.assignment_decision_level(s, assignment)

          if level > 0 do
            assert is_integer(
                     out(s, :assignment_decision, [assignment, level], "clingo_literal_t")
                   )

            first = out(s, :assignment_trail_begin, [assignment, level], "uint32_t")
            last = out(s, :assignment_trail_end, [assignment, level], "uint32_t")
            assert last > first

            assert is_integer(
                     out(s, :assignment_trail_at, [assignment, first], "clingo_literal_t")
                   )
          end

          send(owner, :propagated)
          true
        end)

      undo =
        field_callback(s, "clingo_propagator_t", :undo, fn _, _, _, _ ->
          send(owner, :undone)
          :ok
        end)

      decide =
        field_callback(s, "clingo_propagator_t", :decide, fn _, _, fallback, _, result ->
          Clingo.write(s, result, fallback)
          send(owner, :decided)
          true
        end)

      check = field_callback(s, "clingo_propagator_t", :check, fn _, _ -> true end)
      c = ground(s, control(s, ["0", "--opt-mode=ignore"]), "{a}.")

      prop =
        struct(s, "clingo_propagator_t", %{
          init: init,
          propagate: propagate,
          undo: undo,
          decide: decide,
          check: check
        })

      assert A.control_register_propagator(s, c, prop, nil, false)
      h = handle(s, c)
      assert models(s, h) |> Enum.uniq() |> Enum.sort() == [[], ["a"]]
      assert_receive :propagated
      assert_receive :undone
      assert_receive :decided
    end)
  end

  test "model literals, consequences and solve-control clauses" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "{a;b}.")
      atoms = out(s, :control_symbolic_atoms, [c], "clingo_symbolic_atoms_t*")

      it =
        out(s, :symbolic_atoms_find, [atoms, symbol(s, "a")], "clingo_symbolic_atom_iterator_t")

      lit = out(s, :symbolic_atoms_literal, [atoms, it], "clingo_literal_t")
      h = handle(s, c)
      assert A.solve_handle_resume(s, h)
      model = out(s, :solve_handle_model, [h], "clingo_model_t*")
      truth = out(s, :model_is_true, [model, lit], "bool")
      assert truth == out(s, :model_contains, [model, symbol(s, "a")], "bool")
      assert out(s, :model_is_consequence, [model, lit], "clingo_consequence_t") in [0, 1, 2]
      context = out(s, :model_context, [model], "clingo_solve_control_t*")
      assert A.solve_control_add_clause(s, context, Clingo.array(s, "clingo_literal_t", [lit]), 1)
      for model <- models(s, h), do: assert("a" in model)
    end)
  end
end
