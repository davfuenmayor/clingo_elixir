defmodule Clingo.InventoryTest do
  use ExUnit.Case, async: true
  alias Clingo.TestSupport.Raw, as: A

  test "native capability dependencies and value adapters match their reviewed inventories" do
    header =
      File.read!("c_src/clingo.h")
      |> String.replace(~r{//[^\n]*}, "")
      |> String.replace(~r/^#.*$/m, "")

    names =
      Regex.scan(~r/CLINGO_VISIBILITY_DEFAULT\s+[^;]+?\b(clingo_\w+)\s*\([^;]*?\)\s*;/s, header,
        capture: :all_but_first
      )
      |> List.flatten()
      |> Enum.map(&String.to_atom/1)
      |> Enum.sort()

    scope = File.read!("tools/api_scope.json") |> JSON.decode!()

    retained =
      scope["capabilities"]
      |> Map.values()
      |> Enum.flat_map(& &1["operations"])
      |> Enum.map(&String.to_atom/1)
      |> Enum.sort()

    excluded = scope["excluded"] |> Map.keys() |> Enum.map(&String.to_atom/1)
    assert names == Enum.sort(retained ++ excluded)
    assert retained == Clingo.Native.coverage() |> Map.keys() |> Enum.sort()

    adapters =
      (retained -- Enum.map(scope["native_only"], &String.to_atom/1))
      |> Enum.map(fn name ->
        name |> Atom.to_string() |> String.replace_prefix("clingo_", "") |> String.to_atom()
      end)
      |> Enum.sort()

    bindings =
      Clingo.Internal.API.__info__(:functions) |> Keyword.keys() |> Enum.uniq() |> Enum.sort()

    assert bindings == adapters
  end

  test "all public typedefs, enum values and exported globals are described" do
    header = File.read!("c_src/clingo.h") |> String.replace(~r{//[^\n]*}, "")
    constants = Clingo.constants()

    enums =
      Regex.scan(~r/enum clingo_\w+\s*\{(.*?)\}/s, header, capture: :all_but_first)
      |> List.flatten()
      |> Enum.flat_map(fn body ->
        Regex.scan(~r/^\s+(clingo_\w+)\b/m, body, capture: :all_but_first) |> List.flatten()
      end)

    assert length(enums) == 226
    for name <- enums, do: assert(Map.has_key?(constants, String.to_atom(name)))

    typedefs =
      Regex.scan(~r/\b(clingo_\w+_t)\b/, header, capture: :all_but_first)
      |> List.flatten()
      |> Enum.uniq()

    for name <- typedefs, do: assert(Map.has_key?(Clingo.types(), name), "missing type #{name}")

    Clingo.with_session(fn s ->
      for global <- [:g_clingo_ast_constructors, :g_clingo_ast_attribute_names],
          do: assert(Clingo.read(s, Clingo.global(s, global)).size > 0)
    end)
  end

  test "required NULLs, wrong types, oversized arrays and invalid callback contracts are rejected" do
    Clingo.with_session(fn s ->
      assert_raise ArgumentError, fn -> A.symbol_create_number(s, 1, nil) end
      wrong = Clingo.alloc(s, "int")
      assert_raise ArgumentError, fn -> A.control_is_conflicting(s, wrong) end
      symbol = Clingo.alloc(s, "clingo_symbol_t")
      args = Clingo.alloc(s, "clingo_symbol_t", 1)

      assert_raise ArgumentError, fn ->
        A.symbol_create_function(s, "f", args, 2, true, symbol)
      end

      assert_raise ArgumentError, fn -> Clingo.callback(s, "int", fn -> 0 end) end

      assert_raise ArgumentError, fn ->
        A.ast_parse_string(s, "a.", nil, nil, nil, nil, nil, 20)
      end

      assert_raise ArgumentError, fn -> Clingo.alloc(s, "int", -1) end
      assert_raise ArgumentError, fn -> Clingo.alloc(s, "int", 100_000_000) end
      assert_raise ArgumentError, fn -> Clingo.array(s, "char*", ["a\0b"]) end
    end)
  end
end
