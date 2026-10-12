defmodule Clingo.SymbolTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "symbols, signatures, extrema, arrays and strings preserve native semantics" do
    Clingo.with_session(fn s ->
      number = out(s, :symbol_create_number, [-17], "clingo_symbol_t")
      assert out(s, :symbol_number, [number], "int") == -17
      assert A.symbol_type(s, number) == Clingo.constant(:clingo_symbol_type_number)
      assert text(s, number) == "-17"
      args = Clingo.array(s, "clingo_symbol_t", [number])
      f = out(s, :symbol_create_function, ["f", args, 1, false], "clingo_symbol_t")
      assert text(s, f) == "-f(-17)"
      assert out(s, :symbol_name, [f], "char*") == "f"
      assert out(s, :symbol_is_negative, [f], "bool")
      refute out(s, :symbol_is_positive, [f], "bool")
      assert A.symbol_is_equal_to(s, f, symbol(s, "-f(-17)"))
      assert is_integer(A.symbol_hash(s, f))
      ptr = Clingo.alloc(s, "clingo_symbol_t*")
      size = Clingo.alloc(s, "size_t")
      assert A.symbol_arguments(s, f, ptr, size)
      assert Clingo.read(s, size) == 1
      assert Clingo.read(s, Clingo.read(s, ptr)) == number
      string = out(s, :symbol_create_string, ["héllo"], "clingo_symbol_t")
      assert out(s, :symbol_string, [string], "char*") == "héllo"
      id = out(s, :symbol_create_id, ["a", true], "clingo_symbol_t")
      low = out(s, :symbol_create_infimum, [], "clingo_symbol_t")
      high = out(s, :symbol_create_supremum, [], "clingo_symbol_t")
      assert A.symbol_is_less_than(s, low, id)
      assert A.symbol_is_less_than(s, id, high)
      sig = out(s, :signature_create, ["f", 1, false], "clingo_signature_t")
      assert A.signature_name(s, sig) == "f"
      assert A.signature_arity(s, sig) == 1
      assert A.signature_is_negative(s, sig)
      refute A.signature_is_positive(s, sig)
      assert A.signature_is_equal_to(s, sig, sig)
      refute A.signature_is_less_than(s, sig, sig)
      assert is_integer(A.signature_hash(s, sig))
      assert out(s, :add_string, ["interned"], "char*") == "interned"
    end)
  end

  test "native errors are raised without corrupting predicates" do
    Clingo.with_session(fn s ->
      assert_raise Clingo.Error, fn -> symbol(s, "(") end
      a = symbol(s, "a")
      refute A.symbol_is_equal_to(s, a, symbol(s, "b"))
      assert_raise Clingo.Error, fn -> out(s, :symbol_number, [a], "int") end
      assert A.error_string(s, 1) == "runtime error"
      assert is_binary(A.warning_string(s, 0))
    end)
  end

  test "logger callbacks and nested symbol operations run on the native callback thread" do
    Clingo.with_session(fn s ->
      owner = self()

      logger =
        Clingo.callback(s, "clingo_logger_t", fn code, message, _ ->
          send(owner, {:warning, code, message, text(s, symbol(s, "nested"))})
          :ok
        end)

      c = out(s, :control_new, [nil, 0, logger, nil, 20], "clingo_control_t*")
      ground(s, c, "a :- missing.")
      assert_receive {:warning, _, _, "nested"}
    end)
  end
end
