defmodule Clingo.Error do
  defexception [:message, :code]
end

defmodule Clingo do
  @moduledoc """
  Scoped clingo solving with copied Elixir symbols, models and explicit results.
  Prefer `solve!/2`, `models/2` and `with_control/2`. ASP remains the modeling
  language. See `Clingo.Control` for incremental solving and extension hooks.
  Generated C adapters and native session plumbing are private implementation
  details, without a public compatibility promise.

  ## Examples

      iex> Clingo.solve!("a. b :- a.").models |> Enum.map(& &1.shown)
      [["a", "b"]]

      iex> Clingo.models("{a;b}.", models: :all) |> Enum.count()
      4
  """
  defstruct [:native, :dispatcher]

  @doc "Create a control for the duration of fun and release its native session on every exit."
  def with_control(options \\ [], fun) do
    control = Clingo.Control.new!(options)

    Clingo.Scope.run(fn -> fun.(control) end, fn -> Clingo.Control.close(control) end)
  end

  @doc "Solve ASP text or `files:` options, returning copied models and an explicit result."
  def solve!(program_or_options, options \\ [])
  def solve!(options, []) when is_list(options), do: solve!("", options)

  def solve!(program, options) when is_binary(program) do
    Clingo.Options.program(options, :solve)

    with_control(Clingo.Options.constructor_options(options), fn c ->
      Clingo.Control.prepare!(c, program, options)
      Clingo.Control.solve!(c, Clingo.Options.solve_options(options))
    end)
  end

  @doc "Lazily solve ASP text or `files:` options. Every enumeration owns and closes its control."
  def models(program_or_options, options \\ [])
  def models(options, []) when is_list(options), do: models("", options)

  def models(program, options) when is_binary(program) do
    Clingo.Options.program(options, :models)

    Clingo.SolveHandle.stream(
      fn ->
        c = Clingo.Control.new!(Clingo.Options.constructor_options(options))

        Clingo.Scope.on_error(
          fn ->
            Clingo.Control.prepare!(c, program, options)
            Clingo.Control.open_solve(c, Clingo.Options.cursor_options(options))
          end,
          fn -> Clingo.Control.close(c) end
        )
      end,
      fn h ->
        Clingo.Scope.run(fn -> Clingo.SolveHandle.close(h) end, fn ->
          Clingo.Control.close(h.control)
        end)
      end
    )
  end

  @doc false
  def open(options \\ []) do
    Clingo.Options.session(options)

    {:ok, pid} = GenServer.start(Clingo.Dispatcher, {self(), options})

    Clingo.Scope.on_error(
      fn ->
        native = Clingo.Native.open(pid, Keyword.get(options, :max_arena, 256 * 1024 * 1024))
        :ok = GenServer.call(pid, {:attach, native})
        %__MODULE__{native: native, dispatcher: pid}
      end,
      fn -> Clingo.Dispatch.stop(pid) end
    )
  end

  @doc false
  def close(session) do
    if Process.get({__MODULE__, :request}),
      do: raise(ArgumentError, "cannot close a session from a native callback")

    if Process.alive?(session.dispatcher) do
      case Clingo.Dispatch.call(session.dispatcher, {:native, :close, []}, :infinity) do
        {:error, :closed} -> unwrap(Clingo.Native.close(session.native))
        result -> unwrap(result)
      end

      Clingo.Dispatch.stop(session.dispatcher)
    else
      unwrap(Clingo.Native.close(session.native))
    end

    :ok
  end

  @doc false
  def with_session(fun, options \\ []) do
    session = open(options)

    Clingo.Scope.run(fn -> fun.(session) end, fn -> close(session) end)
  end

  @doc false
  def call(session, operation, args, varargs \\ []) do
    case {operation, args, varargs, Process.get({__MODULE__, :request})} do
      {op, [control], [], nil}
      when op in [:clingo_control_interrupt, "clingo_control_interrupt"] ->
        unwrap(Clingo.Native.interrupt(session.native, control))

      {op, [handle], [], nil}
      when op in [:clingo_solve_handle_cancel, "clingo_solve_handle_cancel"] ->
        unwrap(Clingo.Native.cancel(session.native, handle))

      _ ->
        run(session, operation, args ++ varargs)
    end
  end

  @doc false
  def values(session, operation, args), do: run(session, operation, List.to_tuple(args))

  @doc false
  def cancel_cursor(session, cursor) do
    if Process.get({__MODULE__, :request}),
      do:
        raise(
          ArgumentError,
          "cannot wait for cancellation from a native callback; use Control.interrupt!/1"
        )

    unwrap(Clingo.Native.cancel(session.native, cursor))
  end

  @doc false
  def alloc(session, type, count \\ 1), do: run(session, :alloc, {type, count})
  @doc false
  def read(session, pointer, index \\ 0), do: run(session, :read, {pointer, index})
  @doc false
  def write(session, pointer, value, index \\ 0),
    do: run(session, :write, {pointer, index, value})

  @doc false
  def cast(session, pointer, type, count \\ 1), do: run(session, :cast, {pointer, type, count})
  @doc false
  def string(session, pointer, max_bytes), do: run(session, :string, {pointer, max_bytes})
  @doc false
  def global(session, name), do: run(session, :global, {name})
  @doc false
  def call_pointer(session, pointer, args), do: run(session, :call_pointer, {pointer, args})

  @doc false
  def callback(session, type, fun) do
    arity = Clingo.Native.callback_arity(type)

    unless is_integer(arity) and is_function(fun, arity),
      do: raise(ArgumentError, "callback must be a function of arity #{inspect(arity)}")

    id = GenServer.call(session.dispatcher, {:register, fun})

    Clingo.Scope.on_error(
      fn -> run(session, :callback_new, {type, id}) end,
      fn -> GenServer.call(session.dispatcher, {:unregister, id}) end
    )
  end

  @doc false
  def interrupt(control), do: unwrap(Clingo.Native.interrupt(control))
  @doc false
  def finalize_scripts do
    if Process.get({__MODULE__, :request}),
      do: raise(ArgumentError, "cannot finalize scripts from a native callback")

    Clingo.Native.finalize_scripts()
    |> Enum.uniq()
    |> Enum.each(fn pid ->
      if Process.alive?(pid), do: GenServer.stop(pid)
    end)

    :ok
  end

  @doc false
  def constant(name), do: Map.fetch!(Clingo.Native.constants(), name)
  @doc false
  def constants, do: Clingo.Native.constants()
  @doc false
  def type(name), do: Map.fetch!(Clingo.Native.types(), to_string(name))
  @doc false
  def types, do: Clingo.Native.types()

  def version,
    do:
      {constant(:CLINGO_VERSION_MAJOR), constant(:CLINGO_VERSION_MINOR),
       constant(:CLINGO_VERSION_REVISION)}

  @doc false
  def array(session, type, values) do
    if Process.get({__MODULE__, :request}) do
      pointer = alloc(session, type, length(values))
      write_array(session, pointer, values)
      pointer
    else
      run(session, :array_new, {type, values})
    end
  end

  @doc false
  def read_array(_session, nil, 0), do: []
  def read_array(session, pointer, count), do: run(session, :read_array, {pointer, count})

  @doc false
  def write_array(session, pointer, values, index \\ 0) do
    if not is_nil(Process.get({__MODULE__, :request})) and values != [] do
      Enum.reduce(Enum.chunk_every(values, 32), index, fn chunk, at ->
        run(session, :write_array, {pointer, chunk, at})
        at + length(chunk)
      end)

      :ok
    else
      run(session, :write_array, {pointer, values, index})
    end
  end

  @doc false
  def output(session, operation, args, types) when is_list(types) do
    cells = Enum.map(types, &alloc(session, &1))
    result = call(session, operation, args ++ cells)
    {result, cells |> Enum.map(&read(session, &1)) |> List.to_tuple()}
  end

  def output(session, operation, args, type) do
    {result, {value}} = output(session, operation, args, [type])
    {result, value}
  end

  @doc false
  def memory(session), do: run(session, :memory, {})

  @doc false
  def scoped(session, fun) do
    scope = run(session, :scope_open, {})
    key = {__MODULE__, :scope, session.native}
    previous = Process.put(key, scope)

    Clingo.Scope.run(fun, fn ->
      if previous, do: Process.put(key, previous), else: Process.delete(key)
      run(session, :scope_close, {scope})
    end)
  end

  defp run(session, operation, args) do
    context =
      case Process.get({__MODULE__, :scope, session.native}) do
        nil -> []
        scope -> [scope]
      end

    result =
      case Process.get({__MODULE__, :request}) do
        nil ->
          Clingo.Dispatch.call(
            session.dispatcher,
            {:native, :run, [operation, args] ++ context},
            :infinity
          )

        request ->
          case apply(
                 Clingo.Native,
                 :nested,
                 [session.native, request, operation, args] ++ context
               ) do
            {:pending, ref} ->
              receive do
                {:clingo_reply, ^ref, value} -> value
              end

            error ->
              error
          end
      end

    unwrap(result)
  end

  defp unwrap({:ok, value}), do: value
  defp unwrap(:ok), do: :ok

  defp unwrap({:error, {:native_worker_exited, reason}}),
    do: exit({:clingo_native_worker_exited, reason})

  defp unwrap({:error, {code, message}}) when is_integer(code),
    do: raise(Clingo.Error, code: code, message: message || "clingo error")

  defp unwrap({:error, reason}) do
    detail = if is_atom(reason), do: Atom.to_string(reason), else: inspect(reason)
    raise ArgumentError, "clingo: #{detail}"
  end
end
