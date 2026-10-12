#!/usr/bin/env python3
"""Own an isolated local Livebook server and always stop its process tree."""
import argparse
import os
from pathlib import Path
import secrets
import shutil
import signal
import socket
import subprocess
import tempfile
import time


def port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("selection", nargs="?", choices=["downloads"])
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    livebook = shutil.which("livebook") or str(Path.home() / ".mix/escripts/livebook")
    if not Path(livebook).is_file():
        parser.error("install first: mix escript.install hex livebook 0.19.9 --force")
    tag = secrets.token_hex(6)
    cookie = secrets.token_hex(24)
    node = f"clingo_livebooks_{tag}@127.0.0.1"
    http_port, iframe_port = port(), port()
    env = dict(os.environ, LIVEBOOK_IFRAME_PORT=str(iframe_port))
    env.setdefault("ERL_FLAGS", "+S 2:2 +SDcpu 2 +SDio 1")
    subprocess.run(["epmd", "-daemon"], check=True, env=env)
    with tempfile.TemporaryDirectory(prefix="clingo-livebook-server-") as directory:
        env["LIVEBOOK_DATA_PATH"] = directory
        with open(Path(directory) / "server.log", "w+") as log:
            server = subprocess.Popen(
                [livebook, "server", "--ip", "127.0.0.1", "--port", str(http_port),
                 "--name", node, "--cookie", cookie],
                cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT,
                start_new_session=True,
            )
            try:
                deadline = time.monotonic() + 60
                while True:
                    if server.poll() is not None or time.monotonic() >= deadline:
                        log.seek(0)
                        raise RuntimeError("Livebook failed to start:\n" + log.read())
                    try:
                        with socket.create_connection(("127.0.0.1", http_port), timeout=1):
                            break
                    except OSError:
                        time.sleep(0.2)
                command = ["elixir", "--name", f"clingo_checker_{tag}@127.0.0.1",
                           "--cookie", cookie, "tools/check_livebooks_runtime.exs", node]
                if args.selection:
                    command.append(args.selection)
                result = subprocess.run(command, cwd=root, env=env, timeout=7200)
                if result.returncode:
                    raise RuntimeError(f"Livebook checker exited with status {result.returncode}")
            finally:
                try:
                    os.killpg(server.pid, signal.SIGTERM)
                    server.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(server.pid, signal.SIGKILL)
                    server.wait()
                except ProcessLookupError:
                    pass


if __name__ == "__main__":
    main()
