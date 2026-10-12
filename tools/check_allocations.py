#!/usr/bin/env python3
"""Inject wrapper heap and ERTS allocation failures in isolated BEAMs."""
import os
import atexit
import json
from pathlib import Path
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor

root = Path(__file__).resolve().parents[1]
(root / '_build/validation').mkdir(parents=True, exist_ok=True)
def restore():
    subprocess.run(["make", "clean"], cwd=root, check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["make"], cwd=root, check=True, stdout=subprocess.DEVNULL)
atexit.register(restore)
subprocess.run(["make", "clean"], cwd=root, check=True, stdout=subprocess.DEVNULL)
subprocess.run(["make", "CFLAGS=-O2 -g -Wall -Wextra -std=c11 -DCLINGO_FAULT_INJECTION"], cwd=root, check=True)
subprocess.run(["mix", "compile"], cwd=root, check=True)
with tempfile.TemporaryDirectory(prefix="clingo-allocation-") as directory:
    library = str(Path(directory) / "allocation_fault.so")
    subprocess.run(["cc", "-shared", "-fPIC", "-O0", "-Wall", "-Wextra", "-o", library,
                    str(root / "tools/allocation_fault.c"), "-ldl"], check=True)
    upstream_library = str(Path(directory) / "upstream_fault.so")
    subprocess.run(["c++", "-shared", "-fPIC", "-O0", "-Wall", "-Wextra", "-o", upstream_library,
                    str(root / "tools/upstream_fault.cc"), "-ldl"], check=True)
    cases = [("heap", name) for name in ["array", "closure", "callback", "control", "control_reuse", "handle", "ast", "error", "script", "nested", "values", "transient"]]
    cases += [("resource", "control"), ("resource", "callback"), ("resource", "ast"), ("resource", "handle"), ("resource", "values"),
              ("env", "nested"), ("env", "transient"), ("resource", "transient")]
    cases += [("upstream", "control")]
    def check_case(case):
        kind, scenario = case
        checked = 0
        for budget in range(256 if scenario == "transient" else 128 if scenario == "values" else 32):
            env = dict(os.environ, LD_PRELOAD=upstream_library if kind == "upstream" else library,
                       CLINGO_FAIL_ALLOCATION=str(budget),
                       CLINGO_FAIL_KIND=kind, ERL_FLAGS="+S 2:2 +SDcpu 2 +SDio 1")
            result = subprocess.run(["elixir", "-pa", str(root / "_build/dev/lib/clingo_elixir/ebin"),
                                     str(root / "tools/allocation_scenario.exs"), scenario],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=10)
            output = result.stdout + result.stderr
            if result.returncode:
                raise RuntimeError(f"{kind}/{scenario}, allocation {budget}:\n{output}")
            if "ALLOCATION_INJECTED" not in output:
                break
            if "ALLOCATION_RECOVERED" not in output:
                raise RuntimeError(f"Failure did not surface: {kind}/{scenario}, {budget}:\n{output}")
            checked += 1
        if not checked:
            raise RuntimeError(f"No allocation intercepted: {kind}/{scenario}")
        print(f"{kind}/{scenario}: {checked} checks passed", flush=True)
        return dict(kind=kind, scenario=scenario, failures_checked=checked)

    # Each probe runs in its own VM with its own fault budget. Cases may run
    # concurrently; scanning successive budgets within a case stays sequential.
    with ThreadPoolExecutor(max_workers=4) as workers:
        results = list(workers.map(check_case, cases))
    count = sum(case['failures_checked'] for case in results)
    print(f"{count} isolated allocation failure checks passed")
    (root / "_build/validation/allocations.json").write_text(json.dumps(
        dict(result="passed", injected_failures=count, cases=results), indent=2) + "\n")
