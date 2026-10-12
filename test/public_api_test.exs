defmodule Clingo.PublicAPITest do
  use ExUnit.Case, async: true
  alias Clingo.Internal.API, as: A

  test "solve a program using strings, maps, lists and opaque handles" do
    Clingo.with_session(fn s ->
      assert Clingo.version() == {5, 8, 2}
      assert {true, control} = A.control_new(s)
      assert true = A.control_add(s, control, "base", [], "a. b :- a.")
      assert true = A.control_ground(s, control, [%{name: "base", params: []}])
      assert {true, handle} = A.control_solve(s, control)
      assert true = A.solve_handle_resume(s, handle)
      assert {true, model} = A.solve_handle_model(s, handle)
      assert {true, symbols} = A.model_symbols(s, model, :clingo_show_type_shown)

      assert Enum.map(symbols, fn symbol ->
               {true, text} = A.symbol_to_string(s, symbol)
               text
             end)
             |> Enum.sort() == ["a", "b"]

      assert true = A.solve_handle_close(s, handle)
      assert :ok = A.control_free(s, control)
    end)
  end

  test "symbol arrays and native predicates preserve values" do
    Clingo.with_session(fn s ->
      assert {:ok, number} = A.symbol_create_number(s, 42)
      assert {true, function} = A.symbol_create_function(s, "f", [number], true)
      assert {true, [^number]} = A.symbol_arguments(s, function)
      assert {true, "f(42)"} = A.symbol_to_string(s, function)
      assert true = A.symbol_is_equal_to(s, function, function)
    end)
  end

  test "AST constructors accept named attributes and location maps" do
    Clingo.with_session(fn s ->
      location = %{
        begin_file: "test",
        end_file: "test",
        begin_line: 1,
        end_line: 1,
        begin_column: 1,
        end_column: 2
      }

      ast = Clingo.AST.id!(s, %{location: location, name: "a"})
      assert Clingo.AST.to_string!(ast) == "a"
      assert :ok = Clingo.AST.release(ast)
    end)
  end

  test "observer maps accept callback functions and omit optional hooks" do
    parent = self()

    Clingo.with_session(fn s ->
      {true, control} = A.control_new(s)

      assert true =
               A.control_register_observer(
                 s,
                 control,
                 %{
                   init_program: fn incremental, _ ->
                     send(parent, {:init, incremental})
                     true
                   end
                 },
                 false,
                 nil
               )

      assert true = A.control_add(s, control, "base", [], "a.")
      assert true = A.control_ground(s, control, [%{name: "base", params: []}])
      assert_receive {:init, _}
      assert :ok = A.control_free(s, control)
    end)
  end
end
