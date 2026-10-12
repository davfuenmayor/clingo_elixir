defmodule Clingo.IntegerLiteralsTest do
  use ExUnit.Case, async: true
  alias Clingo.{AST, Symbol}

  @boundaries [
    0,
    1,
    2_147_483_647,
    2_147_483_648,
    2_147_483_649,
    4_294_967_295,
    4_294_967_296,
    4_294_967_297,
    Integer.pow(10, 100)
  ]
  @radices [{10, ""}, {16, "0x"}, {8, "0o"}, {2, "0b"}]

  test "textual numbers preserve native 32-bit wrapping in every radix" do
    for magnitude <- @boundaries, sign <- [1, -1], {base, prefix} <- @radices do
      text = literal(magnitude * sign, base, prefix)
      expected = Symbol.number(wrap(magnitude * sign))
      assert Symbol.parse!(text) == expected
      assert Symbol.parse!(to_string(expected)) == expected
      assert Symbol.parse!("f(#{text})").arguments == [expected]
    end

    minimum = Symbol.number(-2_147_483_648)
    assert Symbol.parse!("--2147483648") == minimum
    assert Symbol.parse!("|-2147483648|") == minimum
    assert Symbol.parse!("0xAbCdEf") == Symbol.number(0xABCDEF)
  end

  test "program grounding and ASPIF round trips use the same boundary semantics" do
    entries =
      for magnitude <- @boundaries,
          sign <- [1, -1],
          {base, prefix} <- @radices,
          do: {literal(magnitude * sign, base, prefix), wrap(magnitude * sign)}

    source = Enum.map_join(Enum.with_index(entries), fn {{text, _}, i} -> "a(#{i},#{text})." end)
    expected = Enum.map(Enum.with_index(entries), fn {{_, value}, i} -> "a(#{i},#{value})" end)
    result = Clingo.solve!(source)
    assert Enum.sort(hd(result.models).shown) == Enum.sort(expected)
    assert Clingo.solve!(Clingo.Ground.to_string!(source)).models == result.models

    assert Clingo.solve!("#const n=-0o20000000000. a(n). #show a/0o1.").models ==
             Clingo.solve!("a(-2147483648).").models

    AST.with_ast(fn session ->
      [_, rule] = AST.parse!(session, "a(-2147483648,0o20000000000).")

      assert Clingo.solve!(AST.to_string!(rule)).models ==
               Clingo.solve!("a(-2147483648,-2147483648).").models
    end)
  end

  test "malformed radix literals raise and leave parsing usable" do
    for text <- ["0x", "0xG", "0o8", "0b2"] do
      assert_raise Clingo.Error, fn -> Symbol.parse!(text) end
    end

    assert Symbol.parse!("-2147483648") == Symbol.number(-2_147_483_648)
  end

  defp literal(value, base, prefix),
    do: if(value < 0, do: "-", else: "") <> prefix <> Integer.to_string(abs(value), base)

  defp wrap(value) do
    unsigned = Integer.mod(value, 4_294_967_296)
    if unsigned > 2_147_483_647, do: unsigned - 4_294_967_296, else: unsigned
  end
end
