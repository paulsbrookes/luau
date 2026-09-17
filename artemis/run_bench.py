#!/usr/bin/env python3
"""Run the fixed luau benchmark subset through the interpreter and write
{"bench_total_median_ms": <float>} atomically to the requested output path.

Each script is run once from cwd bench/ (bench_support.lua performs 24
samples, drops the 4 slowest and prints CPU-time milliseconds on a
"|><|<name>|><|<ms>|><|...||_||" line). The metric is the sum over the 8
scripts of the median of the kept samples. Any missing script, missing
result line or non-zero exit fails the run.
"""
import argparse
import json
import os
import statistics
import subprocess
import sys
import tempfile

SCRIPTS = ["base64", "life", "sha256", "sieve", "tictactoe", "trig", "chess", "voxelgen"]
METRIC = "bench_total_median_ms"


def log(msg):
    print(f"[artemis] {msg}", file=sys.stderr, flush=True)


def parse_results(stdout):
    """Return {name: [samples_ms...]} from bench_support.lua report lines."""
    results = {}
    for line in stdout.splitlines():
        line = line.strip()
        if not line.startswith("|><|"):
            continue
        if line.endswith("||_||"):
            line = line[: -len("||_||")]
        parts = line.split("|><|")[1:]  # leading separator -> empty first element
        if len(parts) < 2:
            continue
        name, samples = parts[0], parts[1:]
        results[name] = [float(s) for s in samples]
    return results


def run_script(luau, bench_dir, name):
    script = os.path.join("tests", name + ".lua")
    if not os.path.isfile(os.path.join(bench_dir, script)):
        raise RuntimeError(f"benchmark script missing: {os.path.join(bench_dir, script)}")
    proc = subprocess.run(
        [luau, script],
        cwd=bench_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout)
        sys.stderr.write(proc.stderr)
        raise RuntimeError(f"{name}: luau exited with {proc.returncode}")
    results = parse_results(proc.stdout)
    if len(results) != 1:
        sys.stderr.write(proc.stdout)
        raise RuntimeError(f"{name}: expected exactly one |><| result line, got {len(results)}")
    (bench_name, samples), = results.items()
    if not samples:
        raise RuntimeError(f"{name}: result line has no samples")
    return bench_name, samples


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luau", required=True, help="path to the luau CLI binary")
    ap.add_argument("--bench-dir", required=True, help="path to the bench/ directory")
    ap.add_argument("--output", required=True, help="artemis_results.json destination")
    args = ap.parse_args()

    luau = os.path.abspath(args.luau)
    bench_dir = os.path.abspath(args.bench_dir)
    output = os.path.abspath(args.output)

    per_script = {}
    for name in SCRIPTS:
        bench_name, samples = run_script(luau, bench_dir, name)
        median = statistics.median(samples)
        per_script[name] = median
        log(f"{name:10s} {bench_name!r:40s} n={len(samples):2d} median={median:.3f} ms")

    if len(per_script) != len(SCRIPTS):
        raise RuntimeError(f"expected {len(SCRIPTS)} results, got {len(per_script)}")

    total = float(sum(per_script.values()))
    payload = {METRIC: total}
    for name in SCRIPTS:
        payload[f"median_ms_{name}"] = per_script[name]

    out_dir = os.path.dirname(output)
    fd, tmp_path = tempfile.mkstemp(prefix=".artemis_results.", suffix=".tmp", dir=out_dir)
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(payload, f)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp_path, 0o644)
        os.replace(tmp_path, output)
    except BaseException:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise

    log(f"{METRIC}={total:.3f}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RuntimeError as e:
        log(f"benchmark failed: {e}")
        sys.exit(1)
