Code.require_file("../../tools/raw_probe.exs", __DIR__)

alias Clingo.TestSupport.Raw, as: A
root = System.fetch_env!("CLINGO_PIN_DIR")

wait = fn file ->
  deadline = System.monotonic_time(:millisecond) + 3000

  recur = fn recur ->
    if !File.exists?(Path.join(root, file)) do
      if System.monotonic_time(:millisecond) > deadline, do: raise("gate timeout: #{file}")
      Process.sleep(1)
      recur.(recur)
    end
  end

  recur.(recur)
end

for kind <- [:control, :handle],
    close <- [:object, :session],
    casts <- 0..2,
    cell <- [false, true] do
  for name <- ["entered", "release", "premature"], do: File.rm(Path.join(root, name))
  s = Clingo.open()
  c = Clingo.TestSupport.control(s)
  object = if kind == :control, do: c, else: Clingo.TestSupport.handle(s, c)
  type = if kind == :control, do: "clingo_control_t", else: "clingo_solve_handle_t"

  view =
    Enum.reduce(List.duplicate(:cast, casts), object, fn _, view -> Clingo.cast(s, view, type) end)

  view = if cell, do: Clingo.read(s, Clingo.array(s, type <> "*", [view])), else: view

  interrupt =
    Task.async(fn ->
      try do
        if kind == :control, do: Clingo.interrupt(view), else: A.solve_handle_cancel(s, view)
      rescue
        # Cancel signals first, then revalidates under the call mutex. Close may
        # win the second phase; the signal must still pin native destruction.
        error in ArgumentError ->
          if kind == :handle, do: :closed, else: reraise(error, __STACKTRACE__)
      end
    end)

  wait.("entered")

  free =
    Task.async(fn ->
      case {kind, close} do
        {_, :session} -> Clingo.close(s)
        {:control, :object} -> A.control_free(s, object)
        {:handle, :object} -> A.solve_handle_close(s, object)
      end
    end)

  try do
    # Give the native destruction attempt a chance to reach its drain barrier.
    Process.sleep(20)
    if File.exists?(Path.join(root, "premature")), do: raise("destruction bypassed alias pin")
  after
    File.touch!(Path.join(root, "release"))
    Task.await(interrupt, 5000)
    Task.await(free, 5000)
    Clingo.close(s)
  end

  if File.exists?(Path.join(root, "premature")), do: raise("premature native destruction")
end

IO.puts("PIN_PROBE_OK")
