defmodule Clingo.CallbackTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "observer callbacks and callback exceptions" do
    Clingo.with_session(fn s ->
      owner = self()

      rule =
        field_callback(s, "clingo_ground_program_observer_t", :rule, fn choice,
                                                                        head,
                                                                        nhead,
                                                                        body,
                                                                        nbody,
                                                                        _ ->
          send(
            owner,
            {:rule, choice, Clingo.read_array(s, head, nhead), Clingo.read_array(s, body, nbody)}
          )

          true
        end)

      observer = struct(s, "clingo_ground_program_observer_t", %{rule: rule})
      c = control(s)
      assert A.control_register_observer(s, c, observer, false, nil)
      ground(s, c, "a.")
      assert_receive {:rule, false, [_], []}

      broken =
        field_callback(s, "clingo_ground_program_observer_t", :rule, fn _, _, _, _, _, _ ->
          raise "failed observer"
        end)

      c = control(s)
      observer = struct(s, "clingo_ground_program_observer_t", %{rule: broken})
      assert A.control_register_observer(s, c, observer, false, nil)
      assert_raise Clingo.Error, fn -> ground(s, c, "b.") end
    end)
  end

  test "ground callback can return symbols through an upstream callback pointer" do
    Clingo.with_session(fn s ->
      owner = self()

      callback =
        Clingo.callback(s, "clingo_ground_callback_t", fn location,
                                                          name,
                                                          args,
                                                          size,
                                                          _,
                                                          symbols,
                                                          data ->
          assert Clingo.read(s, location).begin_line == 1
          assert name == "twice"
          [value] = Clingo.read_array(s, args, size)
          number = out(s, :symbol_number, [value], "int")
          answer = symbol(s, Integer.to_string(number * 2))

          assert Clingo.call_pointer(s, symbols, [
                   Clingo.array(s, "clingo_symbol_t", [answer]),
                   1,
                   data
                 ])

          send(owner, :ground_called)
          true
        end)

      c = control(s)
      assert A.control_add(s, c, "base", nil, 0, "a(@twice(3)).")
      parts = Clingo.array(s, "clingo_part_t", [%{name: "base", params: nil, size: 0}])
      assert A.control_ground(s, c, parts, 1, callback, nil)
      assert_receive :ground_called
      assert models(s, handle(s, c)) == [["a(6)"]]
    end)
  end

  test "propagator init, check and assignment callbacks permit native nested calls" do
    Clingo.with_session(fn s ->
      owner = self()

      init =
        field_callback(s, "clingo_propagator_t", :init, fn init, _ ->
          assert A.propagate_init_number_of_threads(s, init) == 1
          A.propagate_init_set_check_mode(s, init, 1)
          assert A.propagate_init_get_check_mode(s, init) == 1
          A.propagate_init_set_undo_mode(s, init, 1)
          assert A.propagate_init_get_undo_mode(s, init) == 1
          assignment = A.propagate_init_assignment(s, init)
          assert A.assignment_decision_level(s, assignment) == 0
          assert A.assignment_root_level(s, assignment) == 0
          refute A.assignment_has_conflict(s, assignment)
          assert A.assignment_size(s, assignment) > 0
          literal = out(s, :assignment_at, [assignment, 0], "clingo_literal_t")
          assert A.assignment_has_literal(s, assignment, literal)
          assert is_boolean(out(s, :assignment_is_fixed, [assignment, literal], "bool"))
          assert is_boolean(out(s, :assignment_is_true, [assignment, literal], "bool"))
          assert is_boolean(out(s, :assignment_is_false, [assignment, literal], "bool"))
          assert out(s, :assignment_level, [assignment, literal], "uint32_t") == 0

          assert out(s, :assignment_truth_value, [assignment, literal], "clingo_truth_value_t") in [
                   0,
                   1,
                   2
                 ]

          assert is_integer(out(s, :assignment_trail_size, [assignment], "uint32_t"))
          atoms = out(s, :propagate_init_symbolic_atoms, [init], "clingo_symbolic_atoms_t*")
          assert out(s, :symbolic_atoms_size, [atoms], "size_t") == 1
          theory = out(s, :propagate_init_theory_atoms, [init], "clingo_theory_atoms_t*")
          assert out(s, :theory_atoms_size, [theory], "size_t") == 0

          it =
            out(
              s,
              :symbolic_atoms_find,
              [atoms, symbol(s, "a")],
              "clingo_symbolic_atom_iterator_t"
            )

          lit = out(s, :symbolic_atoms_literal, [atoms, it], "clingo_literal_t")
          solver_lit = out(s, :propagate_init_solver_literal, [init, lit], "clingo_literal_t")
          assert A.propagate_init_freeze_literal(s, init, solver_lit)
          assert A.propagate_init_add_watch(s, init, solver_lit)
          assert A.propagate_init_add_watch_to_thread(s, init, solver_lit, 0)
          assert A.propagate_init_remove_watch_from_thread(s, init, solver_lit, 0)
          assert A.propagate_init_remove_watch(s, init, solver_lit)
          assert out(s, :propagate_init_propagate, [init], "bool")
          send(owner, {:borrowed, init})
          true
        end)

      check =
        field_callback(s, "clingo_propagator_t", :check, fn control, _ ->
          assert A.propagate_control_thread_id(s, control) == 0
          assignment = A.propagate_control_assignment(s, control)
          assert A.assignment_is_total(s, assignment)
          send(owner, :checked)
          true
        end)

      c = ground(s, control(s), "{a}.")
      propagator = struct(s, "clingo_propagator_t", %{init: init, check: check})
      assert A.control_register_propagator(s, c, propagator, nil, false)
      assert length(models(s, handle(s, c))) == 2
      assert_receive :checked
      assert_receive {:borrowed, init}
      assert_raise ArgumentError, fn -> A.propagate_init_number_of_threads(s, init) end
    end)
  end

  test "solve event callback, model extension and dynamic clauses" do
    Clingo.with_session(fn s ->
      owner = self()

      event =
        Clingo.callback(s, "clingo_solve_event_callback_t", fn type, ptr, _, goon ->
          case type do
            0 ->
              model = Clingo.cast(s, ptr, "clingo_model_t", 1)

              assert A.model_extend(
                       s,
                       model,
                       Clingo.array(s, "clingo_symbol_t", [symbol(s, "extra")]),
                       1
                     )

              context = out(s, :model_context, [model], "clingo_solve_control_t*")

              assert out(s, :solve_control_symbolic_atoms, [context], "clingo_symbolic_atoms_t*") !=
                       nil

              send(owner, {:model, out(s, :model_number, [model], "uint64_t")})

            3 ->
              send(
                owner,
                {:finished, Clingo.read(s, Clingo.cast(s, ptr, "clingo_solve_result_bitset_t"))}
              )

            _ ->
              :ok
          end

          Clingo.write(s, goon, true)
          true
        end)

      c = ground(s, control(s), "{a}.")
      h = out(s, :control_solve, [c, 0, nil, 0, event, nil], "clingo_solve_handle_t*")
      assert out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t") == 5
      assert_receive {:model, _}
      assert_receive {:finished, 5}
    end)
  end
end
