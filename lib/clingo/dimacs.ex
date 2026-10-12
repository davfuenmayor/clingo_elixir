defmodule Clingo.Dimacs do
  @moduledoc """
  Solve DIMACS CNF through the managed ASP solver. Variables are shown as `v(N)`.
  This small text adapter supports the CNF examples in the tutorials; it does not
  invoke clasp or accept other DIMACS problem formats.
  """
  def solve!(text, opts \\ []) when is_binary(text) do
    {variables, clauses} = parse!(text)
    choice = if variables == 0, do: "", else: "{v(1..#{variables})}.\n"

    constraints =
      Enum.map_join(clauses, "\n", fn clause ->
        body =
          Enum.map_join(clause, ",", fn n ->
            if n > 0, do: "not v(#{n})", else: "v(#{-n})"
          end)

        if body == "", do: ":-.", else: ":- #{body}."
      end)

    Clingo.solve!(choice <> constraints, opts)
  end

  defp parse!(text) do
    lines = String.split(text, "\n", trim: true) |> Enum.map(&String.trim/1)
    lines = Enum.reject(lines, &(&1 == "" or String.starts_with?(&1, "c")))

    case lines do
      [header | body] ->
        case String.split(header) do
          ["p", "cnf", variables, count] ->
            variables = natural!(variables)
            count = natural!(count)
            tokens = body |> Enum.flat_map(&String.split/1) |> Enum.map(&integer!/1)

            {clauses, tail} =
              Enum.reduce(tokens, {[], []}, fn
                0, {clauses, current} ->
                  {[Enum.reverse(current) | clauses], []}

                n, {clauses, current} ->
                  if abs(n) > variables,
                    do: raise(ArgumentError, "DIMACS variable exceeds header")

                  {clauses, [n | current]}
              end)

            unless tail == [] and length(clauses) == count,
              do: raise(ArgumentError, "DIMACS clause count or terminator mismatch")

            {variables, Enum.reverse(clauses)}

          _ ->
            raise ArgumentError, "expected DIMACS p cnf header"
        end

      [] ->
        raise ArgumentError, "expected DIMACS p cnf header"
    end
  end

  defp natural!(text) do
    value = integer!(text)
    if value < 0, do: raise(ArgumentError, "negative DIMACS header count")
    value
  end

  defp integer!(text) do
    case Integer.parse(text) do
      {value, ""} -> value
      _ -> raise ArgumentError, "invalid DIMACS integer #{inspect(text)}"
    end
  end
end
