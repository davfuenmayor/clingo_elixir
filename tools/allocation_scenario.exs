Code.require_file("raw_probe.exs", __DIR__)

alias Clingo.TestSupport.Raw, as: A
scenario = hd(System.argv())

run = fn s ->
  case scenario do
    "values" ->
      {true, handle} = Clingo.Internal.API.control_new(s, ["--models=0"])
      c = %Clingo.Control{session: s, handle: handle, owned: false}

      try do
        Clingo.Control.add!(c, "#external enabled. a(42) :- enabled. {b}.")
        Clingo.Control.ground!(c)
        symbol = Clingo.Symbol.function("enabled")
        Clingo.Control.assign_external!(c, symbol, true)
        result = Clingo.Control.solve!(c, symbols: true, assumptions: [{symbol, true}])
        :satisfiable = result.status
        true = Enum.any?(result.models, &("a(42)" in &1.shown))
      after
        # Opening/snapshot failures must release the lease before unwinding.
        0 = map_size(:sys.get_state(s.dispatcher).leases)
      end

    "transient" ->
      {true, handle} = Clingo.Internal.API.control_new(s, [])
      c = %Clingo.Control{session: s, handle: handle, owned: false}
      Clingo.Control.add!(c, "a(@value()).")

      Clingo.Control.ground!(c, [{"base", []}],
        context: %{"value" => fn [] -> Clingo.Symbol.number(42) end}
      )

      try do
        Clingo.Control.solve!(c,
          on_finish: fn _ -> :ok end,
          on_statistics: fn step, _ -> Clingo.Statistics.put!(step, ["custom"], 1) end,
          on_model_view: fn view ->
            Clingo.ModelView.snapshot!(view)
            :cont
          end
        )

        [%{literal: _}] = Clingo.Inspection.symbolic_atoms!(c)
      after
        0 = map_size(:sys.get_state(s.dispatcher).leases)
        # Native retirement messages precede the result that unblocks this call.
        0 = map_size(:sys.get_state(s.dispatcher).callbacks)
      end

    "array" ->
      Clingo.array(s, "char*", ["alpha"])

    "closure" ->
      Clingo.callback(s, "clingo_default_model_printer_t", fn _ -> true end)

    "callback" ->
      callback = Clingo.callback(s, "clingo_default_model_printer_t", fn _ -> true end)
      Clingo.call_pointer(s, callback, [nil])

    "nested" ->
      callback =
        Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
          Clingo.array(s, "int", [42])
          true
        end)

      Clingo.call_pointer(s, callback, [nil])

    scenario when scenario in ["control", "control_reuse", "handle", "ast"] ->
      type =
        case scenario do
          "handle" -> "clingo_solve_handle_t*"
          "ast" -> "clingo_ast_t*"
          _ -> "clingo_control_t*"
        end

      cell = Clingo.alloc(s, type)
      control = fn output -> A.control_new(s, nil, 0, nil, nil, 20, output) end

      operation =
        case scenario do
          "handle" ->
            c = Clingo.alloc(s, "clingo_control_t*")
            true = control.(c)
            c = Clingo.read(s, c)
            fn -> A.control_solve(s, c, 2, nil, 0, nil, nil, cell) end

          "ast" ->
            location =
              Clingo.array(s, "clingo_location_t", [
                %{
                  begin_file: "test",
                  end_file: "test",
                  begin_line: 1,
                  end_line: 1,
                  begin_column: 1,
                  end_column: 2
                }
              ])

            fn ->
              A.ast_build(s, Clingo.constant(:clingo_ast_type_id), cell, [
                {"clingo_location_t*", location},
                {"char*", "a"}
              ])
            end

          "control_reuse" ->
            true = control.(cell)
            :ok = A.control_free(s, Clingo.read(s, cell))
            fn -> control.(cell) end

          _ ->
            fn -> control.(cell) end
        end

      try do
        true = operation.()
      rescue
        e in Clingo.Error ->
          # A failing publication must not expose a freed object. Reused cells
          # may still hold an expired old generation if failure preceded clingo.
          value =
            try do
              Clingo.read(s, cell)
            rescue
              _ in ArgumentError -> nil
            end

          if value != nil, do: raise("owned output survived failed publication")
          reraise(e, __STACKTRACE__)
      end

    "error" ->
      callback =
        Clingo.callback(s, "clingo_default_model_printer_t", fn _ -> raise "diagnostic" end)

      try do
        Clingo.call_pointer(s, callback, [nil])
      rescue
        e in Clingo.Error ->
          if e.code == Clingo.constant(:clingo_error_bad_alloc), do: reraise(e, __STACKTRACE__)
      end

    "script" ->
      {_, _, fields} = Clingo.type("clingo_script_t")
      fields = Map.new(fields, fn {key, _} -> {key, nil} end) |> Map.put(:version, "fault-test")
      api = Clingo.array(s, "clingo_script_t", [fields])
      true = A.register_script(s, "fault_test", api, nil)
  end
end

try do
  Clingo.with_session(fn s ->
    try do
      try do
        run.(s)
      rescue
        e in Clingo.Error ->
          if e.code != Clingo.constant(:clingo_error_bad_alloc), do: reraise(e, __STACKTRACE__)
          pointer = Clingo.array(s, "int", [42])
          42 = Clingo.read(s, pointer)
          IO.puts("ALLOCATION_RECOVERED")
      end
    after
      if scenario == "script", do: Clingo.finalize_scripts()
    end
  end)

  Clingo.with_session(fn s ->
    pointer = Clingo.array(s, "int", [42])
    42 = Clingo.read(s, pointer)
  end)

  IO.puts("ALLOCATION_NOT_REACHED")
rescue
  e in Clingo.Error ->
    if e.code != Clingo.constant(:clingo_error_bad_alloc), do: reraise(e, __STACKTRACE__)
    IO.puts("ALLOCATION_RECOVERED")

  e in ErlangError ->
    if e.original != :enomem, do: reraise(e, __STACKTRACE__)
    IO.puts("ALLOCATION_RECOVERED")
end

:erlang.garbage_collect()
:ok = Clingo.Native.cleanup_wait()
