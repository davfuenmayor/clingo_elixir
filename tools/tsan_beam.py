#!/usr/bin/env python3
"""Load TSan in BEAM, after shell launchers, without preloading build tools.

BEAM is not instrumented: ignore intercepted accesses from its module and disable
TSan's 64-lock deadlock detector. Wrapper/upstream data-race instrumentation stays
active. This is not a BEAM race or deadlock check.
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    if 'CLINGO_TSAN_REAL_ERL' in os.environ:
        args = sys.argv[1:]
        if any('\n' in arg for arg in args):
            raise SystemExit('TSan launcher requires arguments without embedded newlines')
        # erlexec expands Erlang/Elixir flags without starting the emulator.
        command = subprocess.check_output(
            [os.environ['CLINGO_TSAN_REAL_ERL'], '-emu_args_exit', *args], text=True
        ).splitlines()
        bindir = command[command.index('-bindir') + 1]
        root = command[command.index('-root') + 1]
        # --preload affects this executable only. LD_PRELOAD would also load
        # TSan into BEAM's uninstrumented erts_forker and shell/build utilities.
        loader = '/lib64/ld-linux-x86-64.so.2'
        env = dict(os.environ, BINDIR=bindir, ROOTDIR=root, EMU='beam', PROGNAME='erl')
        os.execve(loader, [loader, '--preload', os.environ['CLINGO_TSAN_RUNTIME'],
                          str(Path(bindir)/'beam.smp'), *command], env)
    else:
        real_erl = shutil.which('erl')
        runtime = subprocess.check_output(['gcc', '-print-file-name=libtsan.so'], text=True).strip()
        with tempfile.TemporaryDirectory(prefix='clingo-tsan-launcher-') as directory:
            launcher = Path(directory)/'erl'
            launcher.symlink_to(Path(__file__).resolve())
            env = dict(os.environ, CLINGO_TSAN_REAL_ERL=real_erl, CLINGO_TSAN_RUNTIME=runtime,
                       PATH=directory + os.pathsep + os.environ['PATH'],
                       TSAN_OPTIONS='halt_on_error=1:ignore_noninstrumented_modules=1:detect_deadlocks=0')
            result = subprocess.run(sys.argv[1:], env=env, timeout=300)
            raise SystemExit(result.returncode)


if __name__ == '__main__':
    main()
