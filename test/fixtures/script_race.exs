Code.require_file("../../tools/raw_probe.exs", __DIR__)

alias Clingo.TestSupport.Raw, as: A

# The runner starts a fresh VM for each round: finalization is permanent.
s = Clingo.open()
owner = self()
{_, _, fields} = Clingo.type("clingo_script_t")
{free_type, _} = fields.free

free =
  Clingo.callback(s, free_type, fn data ->
    id = Clingo.read(s, Clingo.cast(s, data, "int"))
    send(owner, {:freed, id})
    :ok
  end)

values = Map.new(fields, fn {field, _} -> {field, nil} end)
script = Clingo.array(s, "clingo_script_t", [Map.merge(values, %{free: free, version: "test"})])
data = for id <- 0..20, do: {id, Clingo.array(s, "int", [id])}
true = A.register_script(s, "race_first", script, elem(hd(data), 1))

tasks =
  for {id, pointer} <- tl(data) do
    Task.async(fn ->
      result =
        try do
          A.register_script(s, "race_#{id}", script, pointer)
        rescue
          ArgumentError -> false
        end

      {id, result}
    end)
  end

finalizer = Task.async(fn -> Clingo.finalize_scripts() end)
accepted = [0 | for(task <- tasks, {id, true} <- [Task.await(task, 5_000)], do: id)]
:ok = Task.await(finalizer, 5_000)

collect = fn recur, ids ->
  receive do
    {:freed, id} -> recur.(recur, [id | ids])
  after
    0 -> ids
  end
end

freed = collect.(collect, [])
if length(freed) != length(Enum.uniq(freed)), do: raise("script free hook called twice")
if Enum.any?(accepted, &(&1 not in freed)), do: raise("script free hook was lost")
:ok = Clingo.close(s)
IO.puts("SCRIPT_RACE_OK")
