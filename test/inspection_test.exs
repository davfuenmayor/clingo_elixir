defmodule Clingo.InspectionTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "symbolic atom iteration, facts, externals and signatures" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "a. #external b(1).")
      atoms = out(s, :control_symbolic_atoms, [c], "clingo_symbolic_atoms_t*")
      assert out(s, :symbolic_atoms_size, [atoms], "size_t") == 2
      it = out(s, :symbolic_atoms_begin, [atoms, nil], "clingo_symbolic_atom_iterator_t")
      finish = out(s, :symbolic_atoms_end, [atoms], "clingo_symbolic_atom_iterator_t")
      assert out(s, :symbolic_atoms_is_valid, [atoms, it], "bool")
      refute out(s, :symbolic_atoms_iterator_is_equal_to, [atoms, it, finish], "bool")
      assert out(s, :symbolic_atoms_next, [atoms, it], "clingo_symbolic_atom_iterator_t") != it
      a = out(s, :symbolic_atoms_find, [atoms, symbol(s, "a")], "clingo_symbolic_atom_iterator_t")
      assert text(s, out(s, :symbolic_atoms_symbol, [atoms, a], "clingo_symbol_t")) == "a"
      assert out(s, :symbolic_atoms_is_fact, [atoms, a], "bool")
      refute out(s, :symbolic_atoms_is_external, [atoms, a], "bool")

      b =
        out(
          s,
          :symbolic_atoms_find,
          [atoms, symbol(s, "b(1)")],
          "clingo_symbolic_atom_iterator_t"
        )

      assert out(s, :symbolic_atoms_is_external, [atoms, b], "bool")
      count = out(s, :symbolic_atoms_signatures_size, [atoms], "size_t")
      assert count == 2
      signatures = Clingo.alloc(s, "clingo_signature_t", count)
      assert A.symbolic_atoms_signatures(s, atoms, signatures, count)

      assert Clingo.read_array(s, signatures, count)
             |> Enum.map(&A.signature_name(s, &1))
             |> Enum.sort() == ["a", "b"]
    end)
  end

  test "configuration inspection and mutation" do
    Clingo.with_session(fn s ->
      c = control(s)
      conf = out(s, :control_configuration, [c], "clingo_configuration_t*")
      root = out(s, :configuration_root, [conf], "clingo_id_t")
      assert out(s, :configuration_map_size, [conf, root], "size_t") > 0
      assert is_binary(out(s, :configuration_description, [conf, root], "char*"))
      assert out(s, :configuration_type, [conf, root], "clingo_configuration_type_bitset_t") > 0
      assert out(s, :configuration_map_has_subkey, [conf, root, "solve"], "bool")
      assert is_binary(out(s, :configuration_map_subkey_name, [conf, root, 0], "char*"))
      key = out(s, :configuration_map_at, [conf, root, "solve.models"], "clingo_id_t")
      assert A.configuration_value_set(s, conf, key, "2")
      assert out(s, :configuration_value_is_assigned, [conf, key], "bool")
      size = out(s, :configuration_value_get_size, [conf, key], "size_t")
      buf = Clingo.alloc(s, "char", size)
      assert A.configuration_value_get(s, conf, key, buf, size)
      assert Clingo.string(s, buf, size) == "2"
      solver = out(s, :configuration_map_at, [conf, root, "solver"], "clingo_id_t")
      assert out(s, :configuration_array_size, [conf, solver], "size_t") == 1
      assert is_integer(out(s, :configuration_array_at, [conf, solver, 0], "clingo_id_t"))
    end)
  end

  test "statistics maps, arrays and writable user statistics" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "{a}.")
      h = handle(s, c)
      models(s, h)
      assert A.solve_handle_close(s, h)
      stats = out(s, :control_statistics, [c], "clingo_statistics_t*")
      root = out(s, :statistics_root, [stats], "uint64_t")
      assert out(s, :statistics_type, [stats, root], "clingo_statistics_type_t") == 3
      assert out(s, :statistics_map_size, [stats, root], "size_t") > 0
      assert out(s, :statistics_map_has_subkey, [stats, root, "summary"], "bool")
      assert is_binary(out(s, :statistics_map_subkey_name, [stats, root, 0], "char*"))
      assert out(s, :statistics_map_at, [stats, root, "summary"], "uint64_t") != 0

      event =
        Clingo.callback(s, "clingo_solve_event_callback_t", fn type, ptr, _, goon ->
          if type == 2 do
            user = Clingo.read(s, Clingo.cast(s, ptr, "clingo_statistics_t*", 2))
            key = out(s, :statistics_root, [user], "uint64_t")
            array = out(s, :statistics_map_add_subkey, [user, key, "test_array", 2], "uint64_t")
            value = out(s, :statistics_array_push, [user, array, 1], "uint64_t")
            assert A.statistics_value_set(s, user, value, 7.5)
            assert out(s, :statistics_value_get, [user, value], "double") == 7.5
            assert out(s, :statistics_array_size, [user, array], "size_t") == 1
            assert out(s, :statistics_array_at, [user, array, 0], "uint64_t") == value
          end

          Clingo.write(s, goon, true)
          true
        end)

      h = out(s, :control_solve, [c, 0, nil, 0, event, nil], "clingo_solve_handle_t*")
      assert A.solve_handle_close(s, h)
    end)
  end
end
