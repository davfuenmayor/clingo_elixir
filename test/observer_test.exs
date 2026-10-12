defmodule Clingo.ObserverTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "every public ground-program observer callback is dispatched from clingo" do
    Clingo.with_session(fn s ->
      owner = self()

      fields = [
        init_program: 2,
        begin_step: 1,
        end_step: 1,
        rule: 6,
        weight_rule: 7,
        minimize: 4,
        project: 3,
        output_atom: 3,
        output_term: 4,
        external: 3,
        assume: 3,
        heuristic: 7,
        acyc_edge: 5,
        theory_term_number: 3,
        theory_term_string: 3,
        theory_term_compound: 5,
        theory_element: 6,
        theory_atom: 5,
        theory_atom_with_guard: 7
      ]

      callbacks =
        Map.new(fields, fn {field, arity} ->
          callback =
            listener(arity, fn args ->
              assert length(args) == arity
              send(owner, {:observed, field})
              true
            end)

          {field, field_callback(s, "clingo_ground_program_observer_t", field, callback)}
        end)

      c = control(s)

      assert A.control_register_observer(
               s,
               c,
               struct(s, "clingo_ground_program_observer_t", callbacks),
               false,
               nil
             )

      ground(s, c, "{q(1)}. #show shown(X):q(X).")
      backend = out(s, :control_backend, [c], "clingo_backend_t*")
      assert A.backend_begin(s, backend)

      atom =
        out(
          s,
          :backend_add_atom,
          [backend, Clingo.array(s, "clingo_symbol_t", [symbol(s, "b")])],
          "clingo_atom_t"
        )

      assert A.backend_rule(s, backend, true, Clingo.array(s, "clingo_atom_t", [atom]), 1, nil, 0)
      weights = Clingo.array(s, "clingo_weighted_literal_t", [%{literal: atom, weight: 1}])

      assert A.backend_weight_rule(
               s,
               backend,
               true,
               Clingo.array(s, "clingo_atom_t", [atom]),
               1,
               1,
               weights,
               1
             )

      assert A.backend_minimize(s, backend, 1, weights, 1)
      assert A.backend_project(s, backend, Clingo.array(s, "clingo_atom_t", [atom]), 1)
      assert A.backend_external(s, backend, atom, 0)
      assert A.backend_assume(s, backend, Clingo.array(s, "clingo_literal_t", [atom]), 1)
      assert A.backend_heuristic(s, backend, atom, 0, 1, 0, nil, 0)
      assert A.backend_acyc_edge(s, backend, 1, 2, nil, 0)
      number = out(s, :backend_theory_term_number, [backend, 1], "clingo_id_t")
      name = out(s, :backend_theory_term_string, [backend, "theory"], "clingo_id_t")

      fun =
        out(
          s,
          :backend_theory_term_function,
          [backend, "f", Clingo.array(s, "clingo_id_t", [number]), 1],
          "clingo_id_t"
        )

      element =
        out(
          s,
          :backend_theory_element,
          [backend, Clingo.array(s, "clingo_id_t", [fun]), 1, nil, 0],
          "clingo_id_t"
        )

      elements = Clingo.array(s, "clingo_id_t", [element])
      assert out(s, :backend_theory_atom, [backend, 0, name, elements, 1], "clingo_atom_t") == 0

      assert out(
               s,
               :backend_theory_atom_with_guard,
               [backend, 0, fun, elements, 1, "=", number],
               "clingo_atom_t"
             ) == 0

      assert A.backend_end(s, backend)
      h = handle(s, c)
      models(s, h)
      for {field, _} <- fields, do: assert_receive({:observed, ^field})
    end)
  end
end
