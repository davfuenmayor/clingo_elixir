defmodule Clingo.ApplicationTest do
  use ExUnit.Case, async: false
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "custom application, option parsing, flags, validation and model printer" do
    Clingo.with_session(fn s ->
      owner = self()
      flag = Clingo.alloc(s, "bool")

      parse =
        Clingo.callback(s, "bool(*)(char*, void*)", fn value, _ ->
          send(owner, {:parsed, value})
          true
        end)

      register =
        field_callback(s, "clingo_application_t", :register_options, fn options, _ ->
          assert A.options_add(
                   s,
                   options,
                   "Test",
                   "value",
                   "Test value",
                   parse,
                   nil,
                   false,
                   "VALUE"
                 )

          assert A.options_add_flag(s, options, "Test", "test-flag", "Test flag", flag)
          true
        end)

      main =
        Clingo.callback(s, "clingo_main_function_t", fn control, files, count, _ ->
          assert Clingo.read_array(s, files, count) == []
          assert Clingo.read(s, flag)
          ground(s, control, "a. b :- missing.")
          h = out(s, :control_solve, [control, 0, nil, 0, nil, nil], "clingo_solve_handle_t*")
          assert A.solve_handle_close(s, h)
          send(owner, :main)
          true
        end)

      printer =
        Clingo.callback(s, "clingo_model_printer_t", fn model, default, data, _ ->
          assert out(s, :model_number, [model], "uint64_t") == 1
          assert Clingo.call_pointer(s, default, [data])
          send(owner, :printed)
          true
        end)

      app =
        struct(s, "clingo_application_t", %{
          program_name:
            field_callback(s, "clingo_application_t", :program_name, fn _ ->
              "clingo-elixir-test"
            end),
          version: field_callback(s, "clingo_application_t", :version, fn _ -> "1.0" end),
          message_limit:
            field_callback(s, "clingo_application_t", :message_limit, fn _ -> 20 end),
          main: main,
          printer: printer,
          register_options: register,
          logger:
            Clingo.callback(s, "clingo_logger_t", fn code, message, _ ->
              send(owner, {:logged, code, message})
              :ok
            end),
          validate_options:
            field_callback(s, "clingo_application_t", :validate_options, fn _ ->
              send(owner, :validated)
              true
            end)
        })

      args = ["--value=hello", "--test-flag", "--outf=3"]
      assert A.main(s, app, Clingo.array(s, "char*", args), length(args), nil) == 10
      assert_receive {:parsed, "hello"}
      assert_receive :validated
      assert_receive :main
      assert_receive {:logged, _, _}
      # outf=3 suppresses normal printing; re-run to exercise model printer
      args = ["--value=second", "--test-flag", "--quiet=0,2,2"]
      assert A.main(s, app, Clingo.array(s, "char*", args), length(args), nil) == 10
      assert_receive :printed
    end)
  end

  test "global script execution, function calls, version and explicit global lifetime" do
    s = Clingo.open()
    owner = self()
    script_name = "elixir_nif_test"
    mode = :atomics.new(1, [])

    script =
      struct(s, "clingo_script_t", %{
        execute:
          field_callback(s, "clingo_script_t", :execute, fn location, code, _ ->
            assert Clingo.read(s, location).begin_line > 0
            send(owner, {:script, code})
            true
          end),
        callable:
          field_callback(s, "clingo_script_t", :callable, fn name, result, _ ->
            Clingo.write(
              s,
              result,
              name == "answer" or (name == "main" and :atomics.get(mode, 1) == 1)
            )

            true
          end),
        call:
          field_callback(s, "clingo_script_t", :call, fn _, name, _, count, callback, data, _ ->
            assert name == "answer"
            assert count == 0

            assert Clingo.call_pointer(s, callback, [
                     Clingo.array(s, "clingo_symbol_t", [symbol(s, "42")]),
                     1,
                     data
                   ])

            true
          end),
        main:
          field_callback(s, "clingo_script_t", :main, fn control, _ ->
            refute A.control_is_conflicting(s, control)
            ground(s, control, "script_main.")
            h = out(s, :control_solve, [control, 0, nil, 0, nil, nil], "clingo_solve_handle_t*")
            assert A.solve_handle_close(s, h)
            send(owner, :script_main)
            true
          end),
        free:
          field_callback(s, "clingo_script_t", :free, fn _ ->
            send(owner, :script_freed)
            :ok
          end),
        version: "1.0"
      })

    assert A.register_script(s, script_name, script, nil)
    assert A.script_version(s, script_name) == "1.0"
    c = ground(s, control(s), "#script (#{script_name})\nsource code\n#end.\na(@answer()).")
    assert_receive {:script, _}
    assert models(s, handle(s, c)) == [["a(42)"]]
    :atomics.put(mode, 1, 1)
    file = Path.join(System.tmp_dir!(), "clingo-script-#{System.unique_integer([:positive])}.lp")
    File.write!(file, "input.")

    try do
      app = struct(s, "clingo_application_t", %{})
      args = [file, "--outf=3"]
      assert A.main(s, app, Clingo.array(s, "char*", args), 2, nil) in [10, 30]
      assert_receive :script_main
    after
      :atomics.put(mode, 1, 0)
      File.rm!(file)
    end

    assert A.register_script(s, script_name <> "_second", script, nil)
    assert_raise ArgumentError, ~r/global_lifetime/, fn -> Clingo.close(s) end
    assert Clingo.finalize_scripts() == :ok
    assert_receive :script_freed
    assert_receive :script_freed
    assert Clingo.close(s) == :ok
  end
end
