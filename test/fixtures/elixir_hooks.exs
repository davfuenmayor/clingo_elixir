Application.ensure_all_started(:ex_unit)
Application.put_env(:ex_unit, :assert_receive_timeout, 1000)
import ExUnit.Assertions
alias Clingo.{CLI, Control, Script, Symbol}
parent = self()
file = Path.join(System.tmp_dir!(), "elixir-hooks-#{System.unique_integer([:positive])}.lp")
File.write!(file, "a. b :- missing.")

try do
  callbacks = %{
    program_name: fn -> "elixir-hooks" end,
    version: fn -> "1" end,
    message_limit: fn -> 20 end,
    register_options: fn options ->
      CLI.option!(
        options,
        "Test",
        "value",
        "A value",
        fn text ->
          send(parent, {:parsed, text})
          true
        end,
        argument: "VALUE"
      )
    end,
    validate_options: fn -> true end,
    logger: fn _, text -> send(parent, {:logged, text}) end,
    printer: fn view, default ->
      assert Clingo.ModelView.snapshot!(view).shown == ["a"]
      send(parent, :printer)
      default.()
      :ok
    end
  }

  assert CLI.run_native!(callbacks, [file, "--value=hello", "--quiet=0,2,2"]) == 10
  assert_receive {:parsed, "hello"}
  assert_receive {:logged, _}
  assert_receive :printer

  # The abandoned yield solve is cancelled before any model is requested.
  assert CLI.run_native!(
           %{
             main: fn control, files ->
               assert files == [file]
               assert_raise ArgumentError, ~r/borrowed/, fn -> Control.close(control) end
               Control.add!(control, "custom.")
               Control.ground!(control)
               assert [%{shown: ["custom"]}] = Control.solve!(control).models

               handle =
                 Clingo.scoped(control.session, fn ->
                   Control.open_solve(control,
                     on_finish: fn _ -> send(parent, :borrowed_app_finished) end
                   )
                 end)

               send(parent, {:escaped_app_cursor, handle})
               :ok
             end
           },
           [file, "--outf=3"]
         ) == 1

  assert_receive :borrowed_app_finished
  assert_receive {:escaped_app_cursor, app_handle}
  assert_raise ArgumentError, ~r/closed/, fn -> Clingo.SolveHandle.model!(app_handle) end

  active = :atomics.new(1, [])

  assert Script.register!("elixir_ux", %{
           version: "1",
           execute: fn location, code ->
             assert location.begin_line > 0
             send(parent, {:execute, code})
             :ok
           end,
           callable: fn name ->
             name == "answer" or (name == "main" and :atomics.get(active, 1) == 1)
           end,
           call: fn _location, "answer", [] -> Symbol.number(42) end,
           main: fn control ->
             Control.add!(control, "script_main.")
             Control.ground!(control)
             assert Enum.any?(Control.solve!(control).models, &("script_main" in &1.shown))

             handle =
               Control.open_solve(control,
                 on_finish: fn _ -> send(parent, :borrowed_script_finished) end
               )

             send(parent, {:escaped_script_cursor, handle})
             send(parent, :script_main)
             :ok
           end,
           free: fn ->
             send(parent, :free)
             :ok
           end
         }) == :ok

  assert [%{shown: ["a(42)"]}] =
           Clingo.solve!("#script (elixir_ux)\nsource code\n#end.\na(@answer()).").models

  assert_receive {:execute, _}
  :atomics.put(active, 1, 1)
  assert CLI.run_native!(%{}, [file, "--outf=3"]) == 1
  assert_receive :script_main
  assert_receive :borrowed_script_finished
  assert_receive {:escaped_script_cursor, script_handle}
  assert_raise ArgumentError, ~r/closed/, fn -> Clingo.SolveHandle.model!(script_handle) end
  assert Clingo.finalize_scripts() == :ok
  assert_receive :free
  IO.puts("ELIXIR_HOOKS_PASS")
after
  File.rm!(file)
end
