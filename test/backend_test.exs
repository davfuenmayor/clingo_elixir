defmodule Clingo.BackendTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "all backend directives build a native program" do
    Clingo.with_session(fn s ->
      c = control(s)
      backend = out(s, :control_backend, [c], "clingo_backend_t*")
      assert A.backend_begin(s, backend)
      sym = Clingo.array(s, "clingo_symbol_t", [symbol(s, "a")])
      a = out(s, :backend_add_atom, [backend, sym], "clingo_atom_t")
      b = out(s, :backend_add_atom, [backend, nil], "clingo_atom_t")
      assert A.backend_rule(s, backend, false, Clingo.array(s, "clingo_atom_t", [a]), 1, nil, 0)
      weights = Clingo.array(s, "clingo_weighted_literal_t", [%{literal: a, weight: 1}])

      assert A.backend_weight_rule(
               s,
               backend,
               false,
               Clingo.array(s, "clingo_atom_t", [b]),
               1,
               1,
               weights,
               1
             )

      assert A.backend_minimize(s, backend, 0, weights, 1)
      assert A.backend_project(s, backend, Clingo.array(s, "clingo_atom_t", [a]), 1)
      assert A.backend_external(s, backend, b, 3)
      assert A.backend_assume(s, backend, Clingo.array(s, "clingo_literal_t", [a]), 1)
      assert A.backend_heuristic(s, backend, a, 0, 1, 0, nil, 0)
      assert A.backend_acyc_edge(s, backend, 1, 2, nil, 0)
      assert A.backend_end(s, backend)
      assert models(s, handle(s, c)) == [["a"]]
    end)
  end

  test "backend theory creation and the complete theory inspection API" do
    Clingo.with_session(fn s ->
      c = control(s)
      backend = out(s, :control_backend, [c], "clingo_backend_t*")
      assert A.backend_begin(s, backend)
      number = out(s, :backend_theory_term_number, [backend, 7], "clingo_id_t")
      string = out(s, :backend_theory_term_string, [backend, "term"], "clingo_id_t")
      terms = Clingo.array(s, "clingo_id_t", [number])
      seq = out(s, :backend_theory_term_sequence, [backend, 1, terms, 1], "clingo_id_t")
      fun = out(s, :backend_theory_term_function, [backend, "f", terms, 1], "clingo_id_t")

      assert is_integer(
               out(s, :backend_theory_term_symbol, [backend, symbol(s, "g(2)")], "clingo_id_t")
             )

      element =
        out(
          s,
          :backend_theory_element,
          [backend, Clingo.array(s, "clingo_id_t", [seq, fun]), 2, nil, 0],
          "clingo_id_t"
        )

      elements = Clingo.array(s, "clingo_id_t", [element])
      assert out(s, :backend_theory_atom, [backend, 0, string, elements, 1], "clingo_atom_t") == 0

      assert out(
               s,
               :backend_theory_atom_with_guard,
               [backend, 0, fun, elements, 1, "=", number],
               "clingo_atom_t"
             ) == 0

      assert A.backend_end(s, backend)
      atoms = out(s, :control_theory_atoms, [c], "clingo_theory_atoms_t*")
      assert out(s, :theory_atoms_size, [atoms], "size_t") == 2
      assert out(s, :theory_atoms_term_number, [atoms, number], "int") == 7
      assert out(s, :theory_atoms_term_name, [atoms, string], "char*") == "term"
      assert out(s, :theory_atoms_term_type, [atoms, number], "clingo_theory_term_type_t") == 4
      ptr = Clingo.alloc(s, "clingo_id_t*")
      size = Clingo.alloc(s, "size_t")
      assert A.theory_atoms_term_arguments(s, atoms, fun, ptr, size)
      assert Clingo.read_array(s, Clingo.read(s, ptr), Clingo.read(s, size)) == [number]
      assert A.theory_atoms_element_tuple(s, atoms, element, ptr, size)
      assert Clingo.read_array(s, Clingo.read(s, ptr), Clingo.read(s, size)) == [seq, fun]
      conditions = Clingo.alloc(s, "clingo_literal_t*")
      assert A.theory_atoms_element_condition(s, atoms, element, conditions, size)
      assert Clingo.read(s, size) == 0
      assert out(s, :theory_atoms_element_condition_id, [atoms, element], "clingo_literal_t") == 0
      assert out(s, :theory_atoms_atom_term, [atoms, 0], "clingo_id_t") == string
      assert A.theory_atoms_atom_elements(s, atoms, 0, ptr, size)
      assert Clingo.read_array(s, Clingo.read(s, ptr), Clingo.read(s, size)) == [element]
      refute out(s, :theory_atoms_atom_has_guard, [atoms, 0], "bool")
      assert out(s, :theory_atoms_atom_has_guard, [atoms, 1], "bool")
      op = Clingo.alloc(s, "char*")
      rhs = Clingo.alloc(s, "clingo_id_t")
      assert A.theory_atoms_atom_guard(s, atoms, 1, op, rhs)
      assert Clingo.read(s, op) == "="
      assert Clingo.read(s, rhs) == number
      assert out(s, :theory_atoms_atom_literal, [atoms, 0], "clingo_literal_t") == 0

      for {size_fun, text_fun, id} <- [
            {:theory_atoms_term_to_string_size, :theory_atoms_term_to_string, fun},
            {:theory_atoms_element_to_string_size, :theory_atoms_element_to_string, element},
            {:theory_atoms_atom_to_string_size, :theory_atoms_atom_to_string, 1}
          ] do
        count = out(s, size_fun, [atoms, id], "size_t")
        buffer = Clingo.alloc(s, "char", count)
        assert apply(A, text_fun, [s, atoms, id, buffer, count])
        assert byte_size(Clingo.string(s, buffer, count)) > 0
      end
    end)
  end
end
