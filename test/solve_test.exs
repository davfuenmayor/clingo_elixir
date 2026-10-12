defmodule Clingo.SolveTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A
  import Bitwise

  test "yield models, absence of model, exhaustion and explicit handle lifecycle" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "1 { a; b } 1.")
      h = handle(s, c)
      assert Enum.sort(models(s, h)) == [["a"], ["b"]]
      result = out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t")
      assert (result &&& 1) == 1
      assert (result &&& 4) == 4
      assert out(s, :solve_handle_model, [h], "clingo_model_t*") == nil
      assert A.solve_handle_close(s, h)
      assert_raise ArgumentError, fn -> A.solve_handle_resume(s, h) end
      assert A.control_cleanup(s, c)
      refute A.control_is_conflicting(s, c)
    end)
  end

  test "unsatisfiable, model limit and assumption cores" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "a. :- a.")
      h = handle(s, c)
      assert models(s, h) == []
      assert out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t") == 6
      assert A.solve_handle_close(s, h)
      c = ground(s, control(s, ["1"]), "{a;b}.")
      h = handle(s, c)
      assert length(models(s, h)) == 1
      result = out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t")
      assert (result &&& 1) == 1
      assert (result &&& 4) == 0
      assert A.solve_handle_close(s, h)
      c = ground(s, control(s), "a.")
      atoms = out(s, :control_symbolic_atoms, [c], "clingo_symbolic_atoms_t*")

      it =
        out(s, :symbolic_atoms_find, [atoms, symbol(s, "a")], "clingo_symbolic_atom_iterator_t")

      lit = out(s, :symbolic_atoms_literal, [atoms, it], "clingo_literal_t")
      h = handle(s, c, [-lit])
      assert models(s, h) == []
      ptr = Clingo.alloc(s, "clingo_literal_t*")
      count = Clingo.alloc(s, "size_t")
      assert A.solve_handle_core(s, h, ptr, count)
      assert Clingo.read_array(s, Clingo.read(s, ptr), Clingo.read(s, count)) == [-lit]
    end)
  end

  test "model inspection, costs, priorities and proven optimality" do
    Clingo.with_session(fn s ->
      c =
        ground(
          s,
          control(s, ["0", "--opt-mode=optN"]),
          "1 {a;b} 1. #minimize {1@2,a:a; 2@2,b:b}."
        )

      h = handle(s, c)

      proven =
        Stream.repeatedly(fn ->
          assert A.solve_handle_resume(s, h)
          out(s, :solve_handle_model, [h], "clingo_model_t*")
        end)
        |> Stream.take_while(&(&1 != nil))
        |> Enum.map(fn m ->
          assert out(s, :model_type, [m], "clingo_model_type_t") == 0
          assert out(s, :model_number, [m], "uint64_t") > 0
          assert out(s, :model_thread_id, [m], "clingo_id_t") == 0

          assert out(s, :model_contains, [m, symbol(s, "a")], "bool") or
                   out(s, :model_contains, [m, symbol(s, "b")], "bool")

          count = out(s, :model_cost_size, [m], "size_t")
          assert count == 1
          costs = Clingo.alloc(s, "int64_t", count)
          priorities = Clingo.alloc(s, "clingo_weight_t", count)
          assert A.model_cost(s, m, costs, count)
          assert A.model_priority(s, m, priorities, count)
          assert Clingo.read(s, priorities) == 2
          {out(s, :model_optimality_proven, [m], "bool"), Clingo.read(s, costs)}
        end)

      assert {true, 1} in proven
      assert out(s, :solve_handle_last, [h], "clingo_model_t*") != nil
      assert out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t") == 5
    end)
  end

  test "incremental grounding, externals and control switches" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "#const k=7. #external active. a :- active.")
      assert out(s, :control_has_const, [c, "k"], "bool")
      assert text(s, out(s, :control_get_const, [c, "k"], "clingo_symbol_t")) == "7"
      assert A.control_get_enable_cleanup(s, c)
      assert A.control_set_enable_cleanup(s, c, false)
      refute A.control_get_enable_cleanup(s, c)
      assert A.control_set_enable_enumeration_assumption(s, c, false)
      refute A.control_get_enable_enumeration_assumption(s, c)
      atoms = out(s, :control_symbolic_atoms, [c], "clingo_symbolic_atoms_t*")

      it =
        out(
          s,
          :symbolic_atoms_find,
          [atoms, symbol(s, "active")],
          "clingo_symbolic_atom_iterator_t"
        )

      lit = out(s, :symbolic_atoms_literal, [atoms, it], "clingo_literal_t")

      for {truth, expected} <- [{2, [[]]}, {1, [["a", "active"]]}] do
        assert A.control_assign_external(s, c, lit, truth)
        h = handle(s, c)
        assert models(s, h) == expected
        assert A.solve_handle_close(s, h)
      end

      assert A.control_release_external(s, c, lit)
      assert A.control_remove_minimize(s, c)
      assert A.control_update_project(s, c, nil, 0, false)
      assert A.control_add(s, c, "step", nil, 0, "b.")
      parts = Clingo.array(s, "clingo_part_t", [%{name: "step", params: nil, size: 0}])
      assert A.control_ground(s, c, parts, 1, nil, nil)
      h = handle(s, c)
      assert models(s, h) == [["b"]]
    end)
  end
end
