defmodule Clingo.ASTTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  defp build(s, kind, args) do
    cell = Clingo.alloc(s, "clingo_ast_t*")
    assert A.ast_build(s, Clingo.constant(kind), cell, args)
    Clingo.read(s, cell)
  end

  defp attr(name), do: Clingo.constant(String.to_atom("clingo_ast_attribute_#{name}"))

  defp location(s),
    do:
      Clingo.array(s, "clingo_location_t", [
        %{
          begin_file: "<test>",
          end_file: "<test>",
          begin_line: 1,
          end_line: 1,
          begin_column: 1,
          end_column: 2
        }
      ])

  defp term(s, value),
    do:
      build(s, :clingo_ast_type_symbolic_term, [
        {"clingo_location_t*", location(s)},
        {"clingo_symbol_t", symbol(s, value)}
      ])

  test "variadic construction, exported tables, scalar attributes and AST ownership" do
    Clingo.with_session(fn s ->
      table = Clingo.read(s, Clingo.global(s, :g_clingo_ast_constructors))
      assert table.size > 40
      assert Clingo.read(s, table.constructors).name == "id"
      names = Clingo.read(s, Clingo.global(s, :g_clingo_ast_attribute_names))
      assert names.size > 30
      assert is_binary(Clingo.read(s, names.names))
      node = term(s, "7")
      assert ast_text(s, node) == "7"

      assert out(s, :ast_get_type, [node], "clingo_ast_type_t") ==
               Clingo.constant(:clingo_ast_type_symbolic_term)

      assert out(s, :ast_has_attribute, [node, attr(:symbol)], "bool")
      refute out(s, :ast_has_attribute, [node, attr(:name)], "bool")

      assert out(s, :ast_attribute_type, [node, attr(:symbol)], "clingo_ast_attribute_type_t") ==
               1

      assert text(s, out(s, :ast_attribute_get_symbol, [node, attr(:symbol)], "clingo_symbol_t")) ==
               "7"

      assert A.ast_attribute_set_symbol(s, node, attr(:symbol), symbol(s, "8"))
      assert ast_text(s, node) == "8"
      assert A.ast_attribute_set_location(s, node, attr(:location), location(s))
      loc = out(s, :ast_attribute_get_location, [node, attr(:location)], "clingo_location_t")
      assert loc.begin_file == "<test>"
      copy = out(s, :ast_copy, [node], "clingo_ast_t*")
      deep = out(s, :ast_deep_copy, [node], "clingo_ast_t*")
      assert A.ast_equal(s, node, copy)
      assert A.ast_equal(s, node, deep)
      refute A.ast_less_than(s, node, copy)
      assert A.ast_hash(s, node) == A.ast_hash(s, copy)
      assert A.ast_acquire(s, copy) == :ok
      assert A.ast_release(s, copy) == :ok
      assert ast_text(s, copy) == "8"
      assert A.ast_release(s, copy) == :ok
      assert_raise ArgumentError, fn -> ast_text(s, copy) end

      assert_raise ArgumentError, fn ->
        A.ast_build(s, 999, Clingo.alloc(s, "clingo_ast_t*"), [])
      end
    end)
  end

  test "number, string, child AST and array attributes" do
    Clingo.with_session(fn s ->
      node =
        build(s, :clingo_ast_type_function, [
          {"clingo_location_t*", location(s)},
          {"char*", "f"},
          {"clingo_ast_t**", Clingo.array(s, "clingo_ast_t*", [term(s, "1")])},
          {"size_t", 1},
          {"int", 0}
        ])

      assert ast_text(s, node) == "f(1)"
      assert out(s, :ast_attribute_get_string, [node, attr(:name)], "char*") == "f"
      assert A.ast_attribute_set_string(s, node, attr(:name), "g")
      assert out(s, :ast_attribute_get_number, [node, attr(:external)], "int") == 0
      assert A.ast_attribute_set_number(s, node, attr(:external), 1)
      assert out(s, :ast_attribute_size_ast_array, [node, attr(:arguments)], "size_t") == 1
      child = out(s, :ast_attribute_get_ast_at, [node, attr(:arguments), 0], "clingo_ast_t*")
      assert ast_text(s, child) == "1"
      assert A.ast_attribute_set_ast_at(s, node, attr(:arguments), 0, term(s, "2"))
      assert A.ast_attribute_insert_ast_at(s, node, attr(:arguments), 1, term(s, "3"))
      assert A.ast_attribute_delete_ast_at(s, node, attr(:arguments), 0)
      assert ast_text(s, node) == "@g(3)"
      atom = build(s, :clingo_ast_type_symbolic_atom, [{"clingo_ast_t*", node}])
      assert A.ast_attribute_set_ast(s, atom, attr(:symbol), term(s, "a"))

      assert ast_text(s, out(s, :ast_attribute_get_ast, [atom, attr(:symbol)], "clingo_ast_t*")) ==
               "a"

      theory =
        build(s, :clingo_ast_type_theory_operator_definition, [
          {"clingo_location_t*", location(s)},
          {"char*", "+"},
          {"int", 1},
          {"int", 0}
        ])

      guard =
        build(s, :clingo_ast_type_theory_guard_definition, [
          {"char**", Clingo.array(s, "char*", ["+"])},
          {"size_t", 1},
          {"char*", "term"}
        ])

      assert out(s, :ast_attribute_size_string_array, [guard, attr(:operators)], "size_t") == 1
      assert out(s, :ast_attribute_get_string_at, [guard, attr(:operators), 0], "char*") == "+"
      assert A.ast_attribute_set_string_at(s, guard, attr(:operators), 0, "-")
      assert A.ast_attribute_insert_string_at(s, guard, attr(:operators), 1, "*")
      assert A.ast_attribute_delete_string_at(s, guard, attr(:operators), 0)
      assert out(s, :ast_attribute_get_string_at, [guard, attr(:operators), 0], "char*") == "*"
      assert is_integer(A.ast_hash(s, theory))

      atomdef =
        build(s, :clingo_ast_type_theory_atom_definition, [
          {"clingo_location_t*", location(s)},
          {"int", 0},
          {"char*", "a"},
          {"int", 0},
          {"char*", "term"},
          {"clingo_ast_t*", guard}
        ])

      assert out(s, :ast_attribute_get_optional_ast, [atomdef, attr(:guard)], "clingo_ast_t*") !=
               nil

      assert A.ast_attribute_set_optional_ast(s, atomdef, attr(:guard), nil)

      assert out(s, :ast_attribute_get_optional_ast, [atomdef, attr(:guard)], "clingo_ast_t*") ==
               nil
    end)
  end

  test "parsing, acquired callback nodes, unpooling and program builder" do
    Clingo.with_session(fn s ->
      owner = self()
      c = control(s)
      builder = out(s, :program_builder_init, [c], "clingo_program_builder_t*")
      assert A.program_builder_begin(s, builder)

      parse =
        Clingo.callback(s, "clingo_ast_callback_t", fn node, _ ->
          assert A.program_builder_add(s, builder, node)
          assert_raise ArgumentError, fn -> A.ast_release(s, node) end
          A.ast_acquire(s, node)
          send(owner, {:ast, node, ast_text(s, node)})
          true
        end)

      assert A.ast_parse_string(s, "a(1;2).", parse, nil, nil, nil, nil, 20)
      assert A.program_builder_end(s, builder)
      assert_receive {:ast, _, "#program base."}
      assert_receive {:ast, node, "a(1;2)."}
      assert ast_text(s, node) == "a(1;2)."

      unpool =
        Clingo.callback(s, "clingo_ast_callback_t", fn ast, _ ->
          send(owner, {:unpool, ast_text(s, ast)})
          true
        end)

      assert A.ast_unpool(s, node, 3, unpool, nil)
      assert_receive {:unpool, "a(1)."}
      assert_receive {:unpool, "a(2)."}
      parts = Clingo.array(s, "clingo_part_t", [%{name: "base", params: nil, size: 0}])
      assert A.control_ground(s, c, parts, 1, nil, nil)
      assert models(s, handle(s, c)) == [["a(1)", "a(2)"]]
      file = Path.join(System.tmp_dir!(), "clingo-#{System.unique_integer([:positive])}.lp")
      File.write!(file, "b.")

      try do
        assert A.ast_parse_files(
                 s,
                 Clingo.array(s, "char*", [file]),
                 1,
                 unpool,
                 nil,
                 nil,
                 nil,
                 nil,
                 20
               )

        assert_receive {:unpool, "b."}
      after
        File.rm!(file)
      end
    end)
  end
end

defmodule Clingo.ASTBoundaryTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "empty constructor arrays, optional children and incorrect array sizes" do
    Clingo.with_session(fn s ->
      location =
        Clingo.array(s, "clingo_location_t", [
          %{
            begin_file: "<test>",
            end_file: "<test>",
            begin_line: 1,
            end_line: 1,
            begin_column: 1,
            end_column: 1
          }
        ])

      cell = Clingo.alloc(s, "clingo_ast_t*")

      args = [
        {"clingo_location_t*", location},
        {"char*", "f"},
        {"clingo_ast_t**", nil},
        {"size_t", 0},
        {"int", 0}
      ]

      assert A.ast_build(s, Clingo.constant(:clingo_ast_type_function), cell, args)
      assert ast_text(s, Clingo.read(s, cell)) == "f"

      args = [
        {"clingo_location_t*", location},
        {"int", 0},
        {"char*", "a"},
        {"int", 0},
        {"char*", "term"},
        {"clingo_ast_t*", nil}
      ]

      assert A.ast_build(s, Clingo.constant(:clingo_ast_type_theory_atom_definition), cell, args)
      child = Clingo.read(s, cell)

      assert out(
               s,
               :ast_attribute_get_optional_ast,
               [child, Clingo.constant(:clingo_ast_attribute_guard)],
               "clingo_ast_t*"
             ) == nil

      args = [
        {"clingo_location_t*", location},
        {"char*", "f"},
        {"clingo_ast_t**", Clingo.alloc(s, "clingo_ast_t*", 1)},
        {"size_t", 2},
        {"int", 0}
      ]

      assert_raise ArgumentError, fn ->
        A.ast_build(s, Clingo.constant(:clingo_ast_type_function), cell, args)
      end

      assert_raise ArgumentError, fn -> A.symbol_to_string(s, symbol(s, "a"), "", 100) end
    end)
  end
end
