defmodule Clingo.Control do
  @moduledoc """
  A mutable clingo control with deterministic session ownership.

  Prefer `Clingo.with_control/2`. Mutating functions return `:ok`; returned
  models and symbols are copied data. Transient hook storage retires after native
  completion; persistent registrations remain scoped to the control/session.
  A control must not be used after `close/1`.
  """
  alias Clingo.Internal.API, as: A
  alias Clingo.Symbol
  import Clingo.Binding, only: [value: 1]
  defstruct [:session, :handle, owned: true]

  def new!(opts \\ []) do
    Clingo.Options.constructor(opts)
    arguments = arguments(opts)
    s = Clingo.open(Keyword.get(opts, :session, []))

    Clingo.Scope.on_error(
      fn ->
        logger =
          case Keyword.get(opts, :logger) do
            nil ->
              nil

            fun when is_function(fun, 2) ->
              fn code, message, _ ->
                fun.(code, message)
                :ok
              end
          end

        %__MODULE__{session: s, handle: value(A.control_new(s, arguments, logger))}
      end,
      fn -> Clingo.close(s) end
    )
  end

  def close(%__MODULE__{owned: false}),
    do: raise(ArgumentError, "cannot close a borrowed callback control")

  def close(%__MODULE__{session: s}) do
    # Interrupt solving before queuing teardown behind its active job. Keep the
    # literal session API's existing close semantics and callback restrictions.
    if is_nil(Process.get({Clingo, :request})), do: Clingo.Native.abort(s.native)
    Clingo.close(s)
  end

  def add!(c, text), do: add!(c, "base", [], text)

  def add!(c, name, parameters, text),
    do:
      Clingo.scoped(c.session, fn ->
        ok(A.control_add(c.session, c.handle, name, parameters, text))
      end)

  def load!(c, path),
    do: Clingo.scoped(c.session, fn -> ok(A.control_load(c.session, c.handle, path)) end)

  def ground!(c, parts \\ [{"base", []}], opts \\ []) do
    Clingo.Options.ground(opts)

    parts =
      Enum.map(parts, fn {name, args} ->
        %{name: name, params: Enum.map(args, &Symbol.encode(c.session, &1))}
      end)

    callback =
      case Keyword.get(opts, :context) do
        nil ->
          nil

        context when is_map(context) ->
          fn location, name, args, count, _, emit, data ->
            fun =
              Map.get(context, name) ||
                raise ArgumentError,
                      "unknown grounding function #{name} at #{inspect(Clingo.read(c.session, location))}"

            arguments =
              Clingo.read_array(c.session, args, count) |> Enum.map(&Symbol.decode(c.session, &1))

            try do
              emit(c.session, emit, data, fun.(arguments))
            rescue
              exception in [ArgumentError, FunctionClauseError] ->
                source = Clingo.read(c.session, location)

                reraise ArgumentError,
                        [
                          message:
                            "grounding function #{name} at #{source.begin_file}:#{source.begin_line}: #{Exception.message(exception)}"
                        ],
                        __STACKTRACE__
            end
          end
      end

    Clingo.scoped(c.session, fn ->
      ok(A.control_ground(c.session, c.handle, parts, callback))
    end)
  end

  @doc false
  def emit(s, callback, data, result) do
    unless match?(%Symbol{}, result) or is_list(result),
      do: raise(ArgumentError, "grounding functions must return a symbol or a list of symbols")

    symbols = result |> List.wrap() |> Enum.map(&Symbol.encode(s, &1))
    Clingo.values(s, :values_emit, [callback, data, symbols])
  end

  @doc "Find a program literal, or return nil when the symbolic atom is absent."
  def literal(c, symbol),
    do: Clingo.values(c.session, :values_literal, [c.handle, Symbol.encode(c.session, symbol)])

  def assign_external!(c, symbol, truth) when truth in [true, false, :free] do
    flag =
      case truth do
        true -> :clingo_truth_value_true
        false -> :clingo_truth_value_false
        :free -> :clingo_truth_value_free
      end

    ok(A.control_assign_external(c.session, c.handle, program_literal(c, symbol), flag))
  end

  def release_external!(c, symbol),
    do: ok(A.control_release_external(c.session, c.handle, program_literal(c, symbol)))

  def cleanup!(c), do: ok(A.control_cleanup(c.session, c.handle))
  def interrupt!(c), do: Clingo.interrupt(c.handle)

  def solve!(c, opts \\ []) do
    Clingo.Options.solve(opts)

    with_solve!(c, Clingo.Options.cursor_options(opts), fn handle ->
      models = collect(handle, opts, [])
      %{Clingo.SolveHandle.result!(handle) | models: models}
    end)
  end

  def with_solve!(c, opts \\ [], fun) do
    handle = open_solve(c, opts)

    Clingo.Scope.run(fn -> fun.(handle) end, fn -> Clingo.SolveHandle.close(handle) end)
  end

  def models(c, opts \\ []) do
    Clingo.Options.cursor(opts)

    Clingo.SolveHandle.stream(fn -> open_solve(c, opts) end)
  end

  @doc false
  def prepare!(c, program, opts) do
    Enum.each(Keyword.get(opts, :files, []), &load!(c, &1))
    add!(c, program)
    ground!(c, [{"base", []}], Keyword.take(opts, [:context]))
  end

  @doc false
  def open_solve(c, opts) do
    Clingo.Options.cursor(opts)

    lease =
      case dispatch(c, {:lease, c.handle}) do
        {:ok, ref} -> ref
        {:error, reason} -> raise ArgumentError, "clingo: #{reason}"
      end

    Clingo.Scope.on_error(
      fn ->
        Clingo.scoped(c.session, fn ->
          if models = opts[:models],
            do: Clingo.Configuration.put!(c, ["solve", "models"], model_limit(models))

          assumptions =
            Enum.map(Keyword.get(opts, :assumptions, []), fn
              n when is_integer(n) ->
                n

              {symbol, sign} when is_boolean(sign) ->
                Clingo.values(c.session, :values_assumption, [
                  c.handle,
                  Symbol.encode(c.session, symbol),
                  sign
                ])
            end)

          assumptions = Enum.reject(assumptions, &is_nil/1)
          mode = if Keyword.get(opts, :async, false), do: 3, else: 2

          %Clingo.SolveHandle{
            control: c,
            lease: lease,
            handle:
              Clingo.values(c.session, :values_open, [
                c.handle,
                assumptions,
                mode,
                Clingo.Callbacks.solve(c.session, opts)
              ]),
            options: opts
          }
        end)
      end,
      fn -> dispatch(c, {:release_lease, c.handle, lease}) end
    )
  end

  defp collect(h, opts, acc) do
    case Clingo.SolveHandle.next!(h) do
      nil ->
        Enum.reverse(acc)

      model ->
        acc = if Keyword.get(opts, :collect, true), do: [model | acc], else: acc

        case if(fun = Keyword.get(opts, :on_model), do: fun.(model), else: :cont) do
          :cont ->
            collect(h, opts, acc)

          :halt ->
            Clingo.SolveHandle.cancel!(h)
            Enum.reverse(acc)

          other ->
            raise ArgumentError, "on_model must return :cont or :halt, got: #{inspect(other)}"
        end
    end
  end

  def register_propagator!(c, hooks, opts \\ []) do
    Clingo.Options.propagator(opts)
    idle!(c)

    true =
      A.control_register_propagator(
        c.session,
        c.handle,
        Clingo.Extensions.adapt(c.session, "clingo_propagator_t", hooks),
        nil,
        Keyword.get(opts, :sequential, false)
      )

    :ok
  end

  def register_observer!(c, hooks, opts \\ []) do
    Clingo.Options.observer(opts)
    idle!(c)

    true =
      A.control_register_observer(
        c.session,
        c.handle,
        Clingo.Extensions.adapt(c.session, "clingo_ground_program_observer_t", hooks),
        Keyword.get(opts, :replace, false),
        nil
      )

    :ok
  end

  def get_const!(c, name),
    do:
      Clingo.scoped(c.session, fn ->
        Symbol.decode(c.session, value(A.control_get_const(c.session, c.handle, name)))
      end)

  @doc false
  def idle!(c) do
    case dispatch(c, {:idle, c.handle}) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, "clingo: #{reason}"
    end
  end

  defp dispatch(c, message) do
    case Clingo.Dispatch.call(c.session.dispatcher, message) do
      {:error, :closed} -> raise ArgumentError, "clingo: closed"
      result -> result
    end
  end

  defp program_literal(_c, literal) when is_integer(literal), do: literal
  defp program_literal(c, symbol), do: literal(c, symbol) || 0
  defp ok(true), do: :ok
  defp ok(:ok), do: :ok

  defp arguments(opts) do
    args = Keyword.get(opts, :arguments, [])

    case Keyword.fetch(opts, :models) do
      :error ->
        args

      {:ok, models} ->
        if Enum.any?(args, &Regex.match?(~r/^(?:\d+|-n|--models)(?:=|\d|$)/, &1)),
          do: raise(ArgumentError, "models conflicts with native model-limit arguments")

        ["--models=#{model_limit(models)}" | args]
    end
  end

  defp model_limit(:all), do: "0"
  defp model_limit(n), do: Integer.to_string(n)
end
