#!/usr/bin/env python3
"""Verify deterministic bindings, public AST metadata and loader drift rejection."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
(root / '_build/validation').mkdir(parents=True, exist_ok=True)
prefix = Path(os.environ.get('CLINGO_PREFIX', root / '_upstream')).resolve()
paths = ['c_src/api.inc', 'c_src/adapters.inc', 'lib/clingo/internal/api.ex',
         'lib/clingo/binding_metadata.ex',
         'tools/api.json', 'docs/COVERAGE.md']

def run(args, **options):
    return subprocess.run(args, cwd=root, check=True, text=True, **options)

def hashes():
    return {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in paths}

# Format generated Elixir with the project formatter before comparing committed
# outputs: generation intentionally emits compact, formatter-independent text.
run(['make', 'generate'])
run(['mix', 'format'])
first = hashes()
run(['make', 'generate'])
run(['mix', 'format'])
assert hashes() == first, 'Generated bindings differ on the second generation'

run(['mix', 'compile'])

with tempfile.TemporaryDirectory(prefix='clingo-generation-') as directory:
    work = Path(directory)
    cc = os.environ.get('CC', 'cc')
    run([cc, '-I', str(root / 'c_src'), str(root / 'tools/dump_ast.c'),
         '-L', str(prefix / 'lib'), '-lclingo', '-Wl,-rpath,' + str(prefix / 'lib'),
         '-o', str(work / 'dump_ast')])
    actual = json.loads(subprocess.check_output([work / 'dump_ast'], text=True))
    assert actual == json.loads((root / 'tools/ast_constructors.json').read_text()), 'AST metadata drift'
    # Corrupt only the expected metadata in an isolated build, then verify that
    # the actual VM refuses this NIF. Never alter the installed project library.
    source = work / 'c_src'
    shutil.copytree(root / 'c_src', source)
    adapters = source / 'adapters.inc'
    content = adapters.read_text()
    target = 'constructors[0].name, "id"'
    assert target in content
    adapters.write_text(content.replace(target, 'constructors[0].name, "deliberate_drift"', 1))
    app = work / 'clingo_elixir'
    (app / 'ebin').mkdir(parents=True)
    (app / 'priv').mkdir()
    for name in ['Elixir.Clingo.Native.beam', 'clingo_elixir.app']:
        shutil.copy2(root / '_build/dev/lib/clingo_elixir/ebin' / name, app / 'ebin' / name)
    include = subprocess.check_output(['elixir', '-e', 'IO.puts(Path.join(:code.root_dir(), "usr/include"))'], text=True).strip()
    run([cc, '-O1', '-std=c11', '-D_POSIX_C_SOURCE=200809L', '-fPIC', '-shared',
         '-I', include, '-I', str(source), str(source / 'clingo_elixir.c'),
         '-L', str(prefix / 'lib'), '-lclingo', '-lpthread', '-Wl,-rpath,$ORIGIN',
         '-o', str(app / 'priv/clingo_elixir.so')])
    shutil.copy2(prefix / 'lib/libclingo.so.4', app / 'priv/libclingo.so.4')
    code = 'case Code.ensure_loaded(Clingo.Native) do {:error, :on_load_failure} -> IO.puts("DRIFT_REJECTED"); other -> raise inspect(other) end'
    result = run(['elixir', '-pa', str(app / 'ebin'), '-e', code], capture_output=True)
    assert 'DRIFT_REJECTED' in result.stdout, result.stdout + result.stderr

report = {'deterministic_generation': 'passed', 'exported_ast_metadata': 'passed',
          'loader_drift_rejection': 'passed', 'generated_sha256': first}
(root / '_build/validation/generation.json').write_text(json.dumps(report, indent=2) + '\n')
print('Generation, AST metadata and loader drift checks passed')
