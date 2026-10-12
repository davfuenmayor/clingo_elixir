Code.require_file("../../tools/raw_probe.exs", __DIR__)

alias Clingo.TestSupport.Raw, as: A
parent = self()

make_script = fn s, callbacks ->
  {_, _, fields} = Clingo.type("clingo_script_t")
  values = Map.new(fields, fn {field, _} -> {field, nil} end)

  values =
    Enum.reduce(callbacks, values, fn {field, fun}, values ->
      {type, _} = fields[field]
      Map.put(values, field, Clingo.callback(s, type, fun))
    end)

  Clingo.array(s, "clingo_script_t", [Map.put(values, :version, "lifecycle")])
end

case hd(System.argv()) do
  "concurrent" ->
    s = Clingo.open()

    script =
      make_script.(s, %{
        execute: fn _, _, _ -> true end,
        callable: fn name, result, _ ->
          Clingo.write(s, result, name == "answer")
          true
        end,
        call: fn _, _, _, _, inject, data, _ ->
          values = [System.unique_integer([:positive])]
          buffer = Clingo.array(s, "int", values)
          # Both foreign native threads share the script session's cursor list.
          # Exercise independent controls, then leave a cursor for callback cleanup.
          c = %Clingo.Control{session: s, handle: Clingo.TestSupport.control(s)}
          Clingo.Control.add!(c, "{b}.")
          Clingo.Control.ground!(c)

          for _ <- 1..30 do
            Clingo.Control.with_solve!(c, [async: true], fn h ->
              Clingo.SolveHandle.resume!(h)
              %Clingo.Model{} = Clingo.SolveHandle.model!(h)
            end)
          end

          h =
            Clingo.Control.open_solve(c,
              async: true,
              on_finish: fn _ ->
                Clingo.memory(s)
                send(parent, :cursor_finished)
              end
            )

          send(parent, {:entered, self(), h})

          receive do
            :continue -> :ok
          end

          ^values = Clingo.read_array(s, buffer, 1)

          {true, symbol} =
            Clingo.output(s, :clingo_parse_term, ["42", nil, nil, 20], "clingo_symbol_t")

          Clingo.call_pointer(s, inject, [Clingo.array(s, "clingo_symbol_t", [symbol]), 1, data])
        end,
        free: fn _ ->
          send(parent, :freed)
          :ok
        end
      })

    true = A.register_script(s, "lifecycle", script, nil)

    Clingo.with_session(fn t ->
      c = Clingo.TestSupport.control(t)
      true = A.control_add(t, c, "base", nil, 0, "#script (lifecycle)\nactivate\n#end.")
    end)

    tasks =
      for _ <- 1..2 do
        Task.async(fn ->
          Clingo.with_session(fn t ->
            Clingo.TestSupport.ground(t, Clingo.TestSupport.control(t), "a(@answer()).")
            :grounded
          end)
        end)
      end

    workers =
      for _ <- 1..2 do
        receive do
          {:entered, pid, handle} -> {pid, handle}
        after
          5_000 -> raise "missing concurrent callback"
        end
      end

    true = length(Enum.uniq_by(workers, &elem(&1, 0))) == 2
    true = Enum.all?(workers, &Process.alive?(elem(&1, 0)))
    finalizer = Task.async(fn -> Clingo.finalize_scripts() end)

    receive do
      :freed -> raise "script freed during active foreign-session callback"
    after
      50 -> :ok
    end

    Enum.each(workers, fn {pid, _} -> send(pid, :continue) end)
    Enum.each(tasks, fn task -> :grounded = Task.await(task, 5_000) end)
    :ok = Task.await(finalizer, 5_000)

    for _ <- workers do
      receive do
        :cursor_finished -> :ok
      after
        1_000 -> raise "cursor finish hook lost during concurrent cleanup"
      end
    end

    for {_, handle} <- workers do
      try do
        Clingo.SolveHandle.model!(handle)
        raise "callback cursor survived its scope"
      rescue
        ArgumentError -> :ok
      end
    end

    receive do
      :freed -> :ok
    after
      1_000 -> raise "script not freed"
    end

    :ok = Clingo.close(s)

  "owner" ->
    {pid, ref} =
      spawn_monitor(fn ->
        s = Clingo.open()

        script =
          make_script.(s, %{
            free: fn _ ->
              send(parent, :freed)
              :ok
            end
          })

        true = A.register_script(s, "lifecycle", script, nil)
        send(parent, {:session, s})
      end)

    s =
      receive do
        {:session, s} -> s
      end

    receive do
      {:DOWN, ^ref, :process, ^pid, :normal} -> :ok
    end

    true = Process.alive?(s.dispatcher)
    "lifecycle" = A.script_version(s, "lifecycle")
    :ok = Clingo.finalize_scripts()

    receive do
      :freed -> :ok
    after
      1_000 -> raise "owner-death cleanup lost"
    end

    :ok = Clingo.close(s)

  "dispatcher" ->
    s = Clingo.open()
    script = make_script.(s, %{execute: fn _, _, _ -> true end})
    true = A.register_script(s, "lifecycle", script, nil)
    ref = Process.monitor(s.dispatcher)
    Process.exit(s.dispatcher, :kill)

    receive do
      {:DOWN, ^ref, :process, _, :killed} -> :ok
    end

    Clingo.with_session(fn t ->
      c = Clingo.TestSupport.control(t)

      try do
        A.control_add(t, c, "base", nil, 0, "#script (lifecycle)\nactivate\n#end.")
        raise "dead dispatcher was accepted"
      rescue
        _ in Clingo.Error -> :ok
      end
    end)

    :ok = Clingo.finalize_scripts()
    :ok = Clingo.close(s)

  "restart" ->
    {:ok, _} = Application.ensure_all_started(:clingo_elixir)
    :ok = Application.stop(:clingo_elixir)
    {:ok, _} = Application.ensure_all_started(:clingo_elixir)

    Clingo.with_session(fn s ->
      :ok = Clingo.write(s, Clingo.alloc(s, "int"), 7)
      script = make_script.(s, %{})

      try do
        A.register_script(s, "lifecycle", script, nil)
        raise "finalized scripting restarted"
      rescue
        _ in ArgumentError -> :ok
      end
    end)
end

IO.puts("SCRIPT_LIFECYCLE_OK")
