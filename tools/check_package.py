#!/usr/bin/env python3
"""Build the actual Hex archive, relocate it, and smoke-test a minimal runtime.

On Linux as root, chroot contains only BEAM/Elixir, their linked libraries and
the built application. No libffi, C compiler, CMake or Python is installed
there. No mounts, container daemon or privileged namespace setup is required.
"""
import hashlib, json, os, re, shutil, subprocess, tarfile, tempfile
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[1]
(root / '_build/validation').mkdir(parents=True, exist_ok=True)

def run(args, **kwargs):
    return subprocess.run(args, check=True, text=True, **kwargs)

smoke = '''
{:ok, _} = Application.ensure_all_started(:clingo_elixir)
%{status: :satisfiable, models: [%{shown: ["a"]}]} = Clingo.solve!("a.")
tasks = for id <- 1..4, do: Task.async(fn ->
  for _ <- 1..20 do
    %{models: [%{shown: [atom]}]} = Clingo.solve!("p(#{id}).")
    true = atom == "p(#{id})"
  end
end)
Enum.each(tasks, &Task.await(&1, 30_000))
minimum = Clingo.Symbol.number(-2_147_483_648)
^minimum = Clingo.Symbol.parse!(to_string(minimum))
^minimum = Clingo.Symbol.parse!("-0o20000000000")
%{models: [%{shown: ["a(-2147483648)"]}]} = Clingo.solve!("a(-2147483648).")
%{models: [%{shown: ["a(42)"]}]} = Clingo.solve!("a(@value()).", context: %{"value" => fn [] -> Clingo.Symbol.number(42) end})
Clingo.AST.with_ast(fn s ->
  [_, ast] = Clingo.AST.parse!(s, "a.")
  "a." = Clingo.AST.to_string!(ast)
end)
reified = Clingo.Ground.to_string!("{a;b}.", format: :reify)
true = String.contains?(reified, "rule(choice(")
aspif = Clingo.Ground.to_string!("a.")
%{models: [%{shown: ["a"]}]} = Clingo.solve!(aspif)
%{status: :satisfiable} = Clingo.Dimacs.solve!("p cnf 1 1\\n1 0")
%{output: output, exit_code: 0} = Clingo.CLI.run!(["--version"])
true = String.contains?(output, "5.8.2")
IO.puts("PACKAGE_RUNTIME_PASS")
'''

with tempfile.TemporaryDirectory(prefix='clingo-package-') as directory:
    work = Path(directory)
    archive = work / 'package.tar'
    run(['mix', 'hex.build', '--output', str(archive)], cwd=root)
    source = work / 'source'
    source.mkdir()
    with tarfile.open(archive) as outer:
        contents = outer.extractfile('contents.tar.gz')
        with tarfile.open(fileobj=contents, mode='r:gz') as inner:
            assert not any('__pycache__' in item.name or item.name.endswith('.pyc') for item in inner.getmembers()), 'Python cache included in source package'
            inner.extractall(source, filter='data')
    # Install the checked bundle without a compiler or upstream checkout.
    env = {key: value for key, value in os.environ.items() if not key.startswith('CLINGO_')}
    tools = work / 'bin'
    tools.mkdir()
    for name in ['sh', 'elixir', 'erl', 'dirname', 'basename', 'readlink']:
        (tools / name).symlink_to(shutil.which(name))
    run([shutil.which('mix'), 'compile'], cwd=source, env=dict(env, PATH=str(tools)))
    assert not (source / '_source').exists(), 'Installation fetched upstream source'
    assert (source / 'priv/upstream.patch').read_bytes() == (source / 'tools/patches/clingo-5.8.2.patch').read_bytes()
    runtime = work / 'runtime'
    runtime.mkdir()
    app = runtime / 'apps/clingo_elixir'
    shutil.copytree(source / '_build/dev/lib/clingo_elixir', app, symlinks=False)
    assert not (app / 'priv/api.json').exists(), 'Contributor ABI inventory leaked into runtime assets'
    (runtime / 'smoke.exs').write_text(smoke)
    libraries = set()

    def dependencies(path):
        if not path.is_file() or path.read_bytes()[:4] != b'\x7fELF': return
        result = subprocess.run(['ldd', str(path)], capture_output=True, text=True)
        assert 'libffi' not in result.stdout, f'Unexpected libffi dependency: {path}'
        for text in re.findall(r'(?:=>\s+)?(/[^\s()]+)', result.stdout):
            lib = Path(text)
            # Application-local libclingo is already relocated with the app.
            if lib.exists() and app not in lib.parents: libraries.add(lib)

    for path in app.joinpath('priv').iterdir():
        dependencies(path)
    run([str(app / 'priv/clingo'), '--version'])
    if os.geteuid() != 0:
        run(['elixir', '-pa', str(app / 'ebin'), str(runtime / 'smoke.exs')])
        raise SystemExit('Relocation passed; root is required for the minimal-runtime chroot acceptance check')

    # Discover installations rather than assuming the container's /usr/local layout.
    roots = subprocess.check_output(['elixir', '-e',
        'IO.puts(:code.root_dir()); IO.puts(Path.dirname(:code.lib_dir(:elixir)))'],
        text=True).splitlines()
    erlang_root, elixir_lib = (Path(path).resolve() for path in roots)
    elixir_root = elixir_lib.parent
    for install in [erlang_root, elixir_root]:
        shutil.copytree(install, runtime / install.relative_to('/'), symlinks=True)
    for relative in ['usr/local/bin', 'bin', 'usr/bin', 'tmp', 'dev', 'etc']:
        (runtime / relative).mkdir(parents=True, exist_ok=True)
    for name in ['elixir', 'erl']:
        target = Path(shutil.which(name)).resolve()
        (runtime / 'usr/local/bin' / name).symlink_to(target)
    for name in ['sh', 'dirname', 'basename', 'readlink']:
        original = Path(shutil.which(name))
        destination = runtime / ('bin' if name == 'sh' else 'usr/bin') / name
        shutil.copy2(original, destination, follow_symlinks=True)
    # Discover dependencies only for executable/shared objects, never entire /lib.
    for path in runtime.rglob('*'):
        if path.is_file() and not path.is_symlink(): dependencies(path)
    for lib in libraries:
        destination = runtime / lib.relative_to('/')
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(lib, destination, follow_symlinks=True)
    for name in ['null', 'urandom', 'random']:
        original = Path('/dev') / name
        stat = original.stat()
        try:
            os.mknod(runtime / 'dev' / name, stat.st_mode, stat.st_rdev)
        except PermissionError:
            # The workspace prohibits mknod. BEAM uses getrandom on Linux;
            # provide bounded fallback fixtures for startup's optional opens.
            (runtime / 'dev' / name).write_bytes(b'' if name == 'null' else os.urandom(65536))
    (runtime / 'etc/passwd').write_text('root:x:0:0:root:/tmp:/bin/sh\n')
    shutil.rmtree(runtime / elixir_lib.relative_to('/') / 'mix')
    (runtime / elixir_root.relative_to('/') / 'bin/mix').unlink()
    assert not list(runtime.rglob('libffi*'))
    assert not (runtime / 'usr/bin/cc').exists()
    # No /proc mount exists in this root: glibc cannot resolve executable
    # $ORIGIN through /proc/self/exe. Test relocation with RUNPATH above,
    # and provide the same bundled library directory explicitly in chroot.
    run([shutil.which('chroot'), str(runtime), '/usr/local/bin/elixir', '--erl', '+S 2:2 +SDcpu 2 +SDio 1',
         '-pa', '/apps/clingo_elixir/ebin', '/smoke.exs'], env=dict(os.environ, HOME='/tmp', PATH='/usr/local/bin:/usr/bin:/bin', LD_LIBRARY_PATH='/apps/clingo_elixir/priv', ELIXIR_ERL_OPTIONS='+fnu'))
    artifact = root / '_release/clingo_elixir.tar'
    artifact.parent.mkdir(exist_ok=True)
    shutil.copy2(archive, artifact)
    archive_hash = hashlib.sha256(artifact.read_bytes()).hexdigest()
    report = {'checked_at': datetime.now(timezone.utc).isoformat(), 'artifact': str(artifact.relative_to(root)), 'archive_sha256': archive_hash, 'bundled_archive': 'passed', 'compiler_free_install': 'passed', 'integer_literal_patch': 'passed', 'relocation': 'passed', 'minimal_runtime': 'passed',
              'libffi': 'absent', 'build_tools': 'absent', 'smoke': ['solve', 'parallel_controls', 'integer_boundaries', 'grounding_callback', 'ast', 'native_reify', 'aspif_roundtrip', 'dimacs', 'specialized_cli']}
    (root / '_build/validation/package.json').write_text(json.dumps(report, indent=2) + '\n')

    print(f"Package acceptance passed: {artifact} (SHA-256 {archive_hash})")
