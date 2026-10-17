Code.require_file("../tools/raw_probe.exs", __DIR__)

defmodule Clingo.TestSupport do
  alias Clingo.TestSupport.Raw, as: A

  def vm(args, timeout \\ 20_000, env \\ []) do
    paths = Path.wildcard(Path.join([Path.dirname(:code.lib_dir(:elixir)), "*", "ebin"]))
    executable = System.find_executable("erl") |> String.to_charlist()
    args = ["-noshell", "-pa"] ++ paths ++ ["-s", "elixir", "start_cli", "-extra"] ++ args

    port =
      Port.open({:spawn_executable, executable}, [
        :binary,
        :exit_status,
        :use_stdio,
        :stderr_to_stdout,
        args: Enum.map(args, &String.to_charlist/1),
        env:
          Enum.map(env, fn {key, value} ->
            {String.to_charlist(key), String.to_charlist(value)}
          end)
      ])

    collect_vm(port, System.monotonic_time(:millisecond) + timeout, [])
  end

  defp collect_vm(port, deadline, output) do
    receive do
      {^port, {:data, data}} ->
        collect_vm(port, deadline, [data | output])

      {^port, {:exit_status, status}} ->
        {output |> Enum.reverse() |> IO.iodata_to_binary(), status}
    after
      max(deadline - System.monotonic_time(:millisecond), 0) ->
        if info = Port.info(port, :os_pid) do
          {:os_pid, pid} = info

          if :os.type() == {:win32, :nt} do
            System.cmd(
              Path.join([System.fetch_env!("SystemRoot"), "System32", "taskkill.exe"]),
              ["/F", "/T", "/PID", to_string(pid)],
              stderr_to_stdout: true
            )
          else
            System.cmd("kill", ["-KILL", to_string(pid)], stderr_to_stdout: true)
          end

          Port.close(port)
        end

        raise "Child VM exceeded its #{deadline} deadline: #{output |> Enum.reverse() |> IO.iodata_to_binary()}"
    end
  end

  def out(s, function, args, type) do
    cell = Clingo.alloc(s, type)
    result = apply(A, function, [s | args ++ [cell]])
    if result not in [true, :ok], do: raise("unexpected native result: #{inspect(result)}")
    Clingo.read(s, cell)
  end

  def control(s, args \\ ["0"]) do
    out(
      s,
      :control_new,
      [Clingo.array(s, "char*", args), length(args), nil, nil, 20],
      "clingo_control_t*"
    )
  end

  def ground(s, control, program) do
    true = A.control_add(s, control, "base", nil, 0, program)
    parts = Clingo.array(s, "clingo_part_t", [%{name: "base", params: nil, size: 0}])
    true = A.control_ground(s, control, parts, 1, nil, nil)
    control
  end

  def symbol(s, value), do: out(s, :parse_term, [value, nil, nil, 20], "clingo_symbol_t")

  def text(s, value) do
    size = out(s, :symbol_to_string_size, [value], "size_t")
    buffer = Clingo.alloc(s, "char", size)
    true = A.symbol_to_string(s, value, buffer, size)
    Clingo.string(s, buffer, size)
  end

  def ast_text(s, ast) do
    size = out(s, :ast_to_string_size, [ast], "size_t")
    buffer = Clingo.alloc(s, "char", size)
    true = A.ast_to_string(s, ast, buffer, size)
    Clingo.string(s, buffer, size)
  end

  def handle(s, control, assumptions \\ []) do
    out(
      s,
      :control_solve,
      [
        control,
        2,
        Clingo.array(s, "clingo_literal_t", assumptions),
        length(assumptions),
        nil,
        nil
      ],
      "clingo_solve_handle_t*"
    )
  end

  def models(s, handle, acc \\ []) do
    true = A.solve_handle_resume(s, handle)

    case out(s, :solve_handle_model, [handle], "clingo_model_t*") do
      nil ->
        Enum.reverse(acc)

      model ->
        count = out(s, :model_symbols_size, [model, 2], "size_t")
        symbols = Clingo.alloc(s, "clingo_symbol_t", count)
        true = A.model_symbols(s, model, 2, symbols, count)
        values = Clingo.read_array(s, symbols, count) |> Enum.map(&text(s, &1)) |> Enum.sort()
        models(s, handle, [values | acc])
    end
  end

  def struct(s, type, values) do
    {_, _, fields} = Clingo.type(type)
    defaults = Map.new(fields, fn {key, {_, _}} -> {key, nil} end)
    Clingo.array(s, type, [Map.merge(defaults, values)])
  end

  def field_callback(s, type, field, fun) do
    {_, _, fields} = Clingo.type(type)
    {callback_type, _} = Map.fetch!(fields, field)
    Clingo.callback(s, callback_type, fun)
  end

  def listener(arity, handler), do: Clingo.Extensions.callback(arity, handler)
end
