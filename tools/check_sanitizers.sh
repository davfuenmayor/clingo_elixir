#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$project_root"
sanitizers=${CLINGO_SANITIZERS:-address,undefined}
if [[ "$sanitizers" != address,undefined && "$sanitizers" != thread ]]; then
  echo 'Use CLINGO_SANITIZERS=address,undefined or thread' >&2
  exit 1
fi
mode=${sanitizers//,/-}
prefix="$project_root/_upstream-$mode"
restore() { make clean >/dev/null; make >/dev/null; }
trap restore EXIT
CLINGO_BUILD_DIR="$project_root/_native-$mode" CLINGO_INSTALL_DIR="$prefix" \
  CLINGO_SANITIZERS="$sanitizers" ./tools/bootstrap.sh
make clean
make CLINGO_PREFIX="$prefix" CFLAGS="-O1 -g -Wall -Wextra -std=c11 -fsanitize=$sanitizers -fno-omit-frame-pointer"
if [[ "$sanitizers" == thread ]]; then
  # Fail closed if the launcher ever stops detecting instrumented NIF races.
  probe_dir=$(mktemp -d)
  include=$(erl -noshell -eval 'io:format("~s/usr/include", [code:root_dir()]), halt().')
  cc -D_XOPEN_SOURCE=700 -g -O1 -fsanitize=thread -shared -fPIC -pthread \
    -I"$include" tools/reproduce_tsan_nif.c -o "$probe_dir/race.so"
  probe_status=0
  ERL_FLAGS='+S 2:2 +SDcpu 2 +SDio 1' python3 tools/tsan_beam.py elixir tools/reproduce_tsan_nif.exs "$probe_dir/race" \
    > "$probe_dir/result.log" 2>&1 || probe_status=$?
  if [[ "$probe_status" != 66 ]] || ! rg -q 'ThreadSanitizer: data race' "$probe_dir/result.log"; then
    cat "$probe_dir/result.log"
    rm -rf "$probe_dir"
    echo "TSan positive control failed (exit $probe_status)" >&2
    exit 1
  fi
  rm -rf "$probe_dir"
  echo 'TSAN_POSITIVE_CONTROL_PASS'
  CLINGO_PREFIX="$prefix" ERL_FLAGS='+S 2:2 +SDcpu 2 +SDio 1' \
    CLINGO_RETAINED_COVERAGE=1 python3 tools/tsan_beam.py elixir -S mix test
else
  runtime=$(gcc -print-file-name=libasan.so)
  LD_PRELOAD="$runtime" ASAN_OPTIONS=detect_leaks=0:handle_segv=0 \
    UBSAN_OPTIONS="halt_on_error=1:suppressions=$project_root/tools/ubsan.supp" \
    CLINGO_PREFIX="$prefix" ERL_FLAGS='+S 2:2 +SDcpu 2 +SDio 1' CLINGO_RETAINED_COVERAGE=1 mix test
fi
