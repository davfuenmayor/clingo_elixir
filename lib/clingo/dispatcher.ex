defmodule Clingo.Dispatcher do
  @moduledoc false
  use GenServer
  require Logger

  def init({owner, options}) do
    {:ok, workers} = Task.Supervisor.start_link()

    {:ok,
     %{
       owner: Process.monitor(owner),
       workers: workers,
       callbacks: %{},
       leases: %{},
       next: 0,
       native: nil,
       pending: %{},
       active: nil,
       command: nil,
       queue: :queue.new(),
       max_queue: Keyword.get(options, :max_queue, 1024),
       max_callbacks: Keyword.get(options, :max_callbacks, 1024)
     }}
  end

  def handle_call({:attach, native}, _, state), do: {:reply, :ok, %{state | native: native}}

  def handle_call({:lease, key}, {owner, _}, state) do
    if Map.has_key?(state.leases, key) do
      {:reply, {:error, :solve_active}, state}
    else
      ref = Process.monitor(owner)
      lease = %{owner: owner, ref: ref, cursor: nil}
      {:reply, {:ok, ref}, %{state | leases: Map.put(state.leases, key, lease)}}
    end
  end

  def handle_call({:release_lease, key, ref}, _, state) do
    case state.leases[key] do
      %{ref: ^ref} ->
        Process.demonitor(ref, [:flush])
        {:reply, :ok, %{state | leases: Map.delete(state.leases, key)}}

      _ ->
        {:reply, :ok, state}
    end
  end

  def handle_call({:idle, key}, _, state),
    do:
      {:reply, if(Map.has_key?(state.leases, key), do: {:error, :solve_active}, else: :ok), state}

  def handle_call({:register, fun}, _, state) do
    {:reply, state.next,
     %{state | next: state.next + 1, callbacks: Map.put(state.callbacks, state.next, fun)}}
  end

  def handle_call({:unregister, id}, _, state),
    do: {:reply, :ok, %{state | callbacks: Map.delete(state.callbacks, id)}}

  # Mutex waiters stay in BEAM processes; only the active call enters a dirty NIF.
  def handle_call({:native, operation, args}, from, state) do
    {logical_operation, logical_args} = command(operation, args)

    if blocked_mutation?(logical_operation, logical_args, state) do
      {:reply, {:error, :solve_active}, state}
    else
      if state.active && :queue.len(state.queue) >= state.max_queue do
        {:reply, {:error, :busy}, state}
      else
        queue = :queue.in({from, operation, args}, state.queue)
        {:noreply, dispatch(%{state | queue: queue})}
      end
    end
  end

  def handle_info(
        {:clingo_result, pid, result},
        %{active: {pid, ref, from}, command: command} = state
      ) do
    Process.demonitor(ref, [:flush])
    state = retain_script_owner(state, command, result)
    state = retain_cursor_owner(state, command, result)
    GenServer.reply(from, result)
    {:noreply, dispatch(%{state | active: nil, command: nil})}
  end

  def handle_info({:clingo_callback, id, request, args}, state) do
    if map_size(state.pending) >= state.max_callbacks do
      Clingo.Native.reply(request, {:error, "callback admission limit exceeded"})
      {:noreply, state}
    else
      callback(state, id, request, args)
    end
  end

  def handle_info({:clingo_unregister, id}, state),
    do: {:noreply, %{state | callbacks: Map.delete(state.callbacks, id)}}

  def handle_info({:clingo_diagnostic, type, {:error, message}}, state) do
    Logger.error("clingo #{type} callback failed: #{inspect(message)}")
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _, _}, %{owner: ref} = state),
    do: {:stop, :normal, state}

  def handle_info({:DOWN, ref, :process, _, reason}, %{active: {_, ref, from}} = state) do
    GenServer.reply(from, {:error, {:native_worker_exited, reason}})
    {:noreply, dispatch(%{state | active: nil, command: nil})}
  end

  def handle_info({:DOWN, ref, :process, _, reason}, state) do
    case Enum.find(state.leases, fn {_, lease} -> lease.ref == ref end) do
      {key, lease} ->
        lease = %{lease | owner: nil}

        leases =
          cond do
            lease.cursor ->
              drain_cursor(state, key, lease)
              Map.put(state.leases, key, lease)

            pending_open?(state, key) ->
              Map.put(state.leases, key, lease)

            true ->
              Map.delete(state.leases, key)
          end

        {:noreply, %{state | leases: leases}}

      nil ->
        {request, pending} = Map.pop(state.pending, ref)

        if request,
          do: Clingo.Native.reply(request, {:error, "callback exited: #{inspect(reason)}"})

        {:noreply, %{state | pending: pending}}
    end
  end

  defp pending_open?(state, key) do
    matches = fn
      {:run, [:values_open, {^key, _, _, _}]} -> true
      _ -> false
    end

    matches.(state.command) or
      Enum.any?(:queue.to_list(state.queue), fn {_, op, args} -> matches.(command(op, args)) end)
  end

  defp retain_cursor_owner(state, {:run, [:values_open, {key, _, _, _}]}, result) do
    case {state.leases[key], result} do
      {nil, _} ->
        state

      {lease, {:ok, cursor}} ->
        lease = %{lease | cursor: cursor}
        if is_nil(lease.owner), do: drain_cursor(state, key, lease)
        %{state | leases: Map.put(state.leases, key, lease)}

      {%{owner: nil}, _} ->
        %{state | leases: Map.delete(state.leases, key)}

      _ ->
        state
    end
  end

  defp retain_cursor_owner(state, _, _), do: state

  defp drain_cursor(state, key, lease) do
    session = %Clingo{native: state.native, dispatcher: self()}

    spawn(fn ->
      try do
        try do
          Clingo.cancel_cursor(session, lease.cursor)
        after
          Clingo.values(session, :values_close, [lease.cursor])
        end
      rescue
        ArgumentError -> :ok
      after
        if Process.alive?(session.dispatcher),
          do: GenServer.call(session.dispatcher, {:release_lease, key, lease.ref})
      end
    end)
  end

  defp blocked_mutation?(:run, [operation, [key | _]], state)
       when operation in [
              :clingo_control_add,
              :clingo_control_load,
              :clingo_control_load_aspif,
              :clingo_control_ground,
              :clingo_control_cleanup,
              :clingo_control_free,
              :clingo_control_assign_external,
              :clingo_control_release_external,
              :clingo_control_remove_minimize,
              :clingo_control_register_propagator,
              :clingo_control_register_observer
            ],
       do: Map.has_key?(state.leases, key)

  defp blocked_mutation?(_, _, _), do: false

  def terminate(_, %{native: native}) when not is_nil(native) do
    spawn(fn ->
      Clingo.Native.abort(native)
      Clingo.Native.close(native)
    end)

    :ok
  end

  def terminate(_, _), do: :ok

  defp callback(state, id, request, args) do
    fun = Map.fetch!(state.callbacks, id)
    session = %Clingo{native: state.native, dispatcher: self()}

    {:ok, pid} =
      Task.Supervisor.start_child(
        state.workers,
        fn ->
          Process.put({Clingo, :request}, request)
          Process.put({Clingo, :session}, session)

          result =
            try do
              {:ok, apply(fun, args)}
            rescue
              exception in Clingo.Error ->
                {:error, {exception.code, Exception.format(:error, exception, __STACKTRACE__)}}

              exception ->
                {:error, Exception.format(:error, exception, __STACKTRACE__)}
            catch
              kind, reason -> {:error, Exception.format(kind, reason, __STACKTRACE__)}
            end

          Clingo.Native.reply(request, result)
        end,
        shutdown: :brutal_kill
      )

    ref = Process.monitor(pid)

    {:noreply, %{state | pending: Map.put(state.pending, ref, request)}}
  end

  defp dispatch(%{active: nil} = state) do
    case :queue.out(state.queue) do
      {{:value, {from, operation, args}}, queue} ->
        dispatcher = self()
        native = state.native

        if Process.alive?(elem(from, 0)) do
          {pid, ref} =
            spawn_monitor(fn ->
              result = apply(Clingo.Native, operation, [native | args])
              send(dispatcher, {:clingo_result, self(), result})
            end)

          %{state | active: {pid, ref, from}, command: command(operation, args), queue: queue}
        else
          state = discard_abandoned_open(state, operation, args)
          dispatch(%{state | queue: queue})
        end

      {:empty, _} ->
        state
    end
  end

  defp dispatch(state), do: state

  defp command(:run, [operation, args, _scope]), do: {:run, [operation, args]}
  defp command(operation, args), do: {operation, args}

  defp discard_abandoned_open(state, :run, [operation, args, _scope]),
    do: discard_abandoned_open(state, :run, [operation, args])

  defp discard_abandoned_open(state, :run, [:values_open, {key, _, _, _}]) do
    case state.leases[key] do
      nil ->
        state

      lease ->
        Process.demonitor(lease.ref, [:flush])
        %{state | leases: Map.delete(state.leases, key)}
    end
  end

  defp discard_abandoned_open(state, _, _), do: state

  defp retain_script_owner(state, {:run, [operation, _]}, {:ok, true})
       when operation in [:clingo_register_script, "clingo_register_script"] do
    if state.owner, do: Process.demonitor(state.owner, [:flush])
    %{state | owner: nil}
  end

  defp retain_script_owner(state, _, _), do: state
end
