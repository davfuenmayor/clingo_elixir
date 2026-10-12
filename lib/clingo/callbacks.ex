defmodule Clingo.Callbacks do
  @moduledoc false

  def solve(s, opts) do
    if Enum.any?(
         [:on_finish, :on_unsat, :on_statistics, :on_model_view],
         &Keyword.has_key?(opts, &1)
       ) do
      Clingo.callback(s, "clingo_solve_event_callback_t", fn type, event, _, goon ->
        case type do
          0 ->
            if fun = opts[:on_model_view] do
              model = Clingo.cast(s, event, "clingo_model_t")
              result = fun.(%Clingo.ModelView{session: s, handle: model})
              Clingo.write(s, goon, continuation(result))
            end

          1 ->
            if fun = opts[:on_unsat] do
              lower = Clingo.read(s, Clingo.cast(s, event, "void*", 2))
              # The second opaque slot contains a size_t value, not an address to read.
              count = Clingo.read(s, Clingo.cast(s, event, "size_t", 2), 1)
              fun.(Clingo.read_array(s, Clingo.cast(s, lower, "int64_t", count), count))
            end

          2 ->
            if fun = opts[:on_statistics] do
              [step, accumulated] =
                Clingo.read_array(s, Clingo.cast(s, event, "clingo_statistics_t*", 2), 2)

              fun.(Clingo.Statistics.view(s, step), Clingo.Statistics.view(s, accumulated))
            end

          3 ->
            if fun = opts[:on_finish],
              do:
                fun.(
                  Clingo.Result.from_native(
                    Clingo.read(s, Clingo.cast(s, event, "clingo_solve_result_bitset_t"))
                  )
                )
        end

        true
      end)
    end
  end

  defp continuation(:cont), do: true
  defp continuation(:halt), do: false

  defp continuation(value),
    do: raise(ArgumentError, "on_model_view must return :cont or :halt, got: #{inspect(value)}")
end
