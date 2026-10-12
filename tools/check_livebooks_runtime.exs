# Run against a local Livebook 0.19.9 node. See livebooks/README.md.
[target | options] = System.argv()
unless options in [[], ["downloads"]], do: raise("usage: NODE [downloads]")
server = String.to_atom(target)
true = Node.connect(server)
root = Path.expand("..", __DIR__)

support = File.read!(Path.join(root, "tools/livebook_check.exs"))

checker = File.read!(Path.join(root, "tools/livebook_runtime_check.exs"))

case :rpc.call(
       server,
       Code,
       :eval_string,
       [
         support <>
           "\n" <> checker <> "\nASPCourseRuntimeCheck.run(#{inspect(root)}, #{inspect(options)})"
       ],
       :infinity
     ) do
  {results, _} when is_list(results) ->
    IO.puts(
      "PASS #{length(results)} Livebook imports; reference-only notebooks reported separately"
    )

  error ->
    raise("Livebook runtime check failed: #{inspect(error)}")
end
