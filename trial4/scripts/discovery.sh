#!/usr/bin/env bash
# Discovery trials for the MergePatch aliasing finding, using fuzz_utils_alias (aliasing calls enabled).
# usage: bash trial4/scripts/discovery.sh <label> <mode: seeded|unseeded> [trials=5] [max_seconds=60]
#   seeded:   starts from trial4/seeds/utils  (the crash shows up while the seeds are loaded, before any mutation)
#   unseeded: starts from an empty corpus     (the crash must be found by mutation)
# Output: results/<label>/discovery_<mode>/discovery.csv (trial,seed,outcome,seconds,executions,signature,artifact) + trial dirs
set -uo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; root="$(cd -- "$here/.." && pwd)"
label="${1:?label}"; mode="${2:?seeded|unseeded}"; trials="${3:-5}"; maxs="${4:-60}"
bin="${BUILD_DIR:-$here/build}/fuzz_utils_alias"; out="$here/results/$label/discovery_$mode"; rm -rf "$out"; mkdir -p "$out"
export ASAN_OPTIONS=detect_leaks=1:symbolize=1:handle_abort=1 UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1
echo "trial,seed,outcome,seconds,executions,signature,artifact" > "$out/discovery.csv"
for i in $(seq 1 "$trials"); do
    seed=$((9000 + i)); td="$out/trial$i"; mkdir -p "$td/corpus" "$td/art"
    seedarg=(); [[ $mode == seeded ]] && seedarg=("$here/seeds/utils")
    s=$(date +%s.%N)
    "$bin" -max_total_time="$maxs" -seed="$seed" -dict="$root/fuzzing/json.dict" -max_len=4096 -timeout=10 -rss_limit_mb=2048 \
        -artifact_prefix="$td/art/" "$td/corpus" "${seedarg[@]}" > "$td/log.txt" 2>&1; rc=$?
    e=$(date +%s.%N); secs=$(python3 -c "print(f'{$e-$s:.2f}')")
    art=$(ls "$td/art" 2>/dev/null | head -n1); sig=$(grep -m1 "^SUMMARY" "$td/log.txt" | sed 's#/[^ ]*/##; s/,/;/g')
    execs=$(grep -E "^#[0-9]+" "$td/log.txt" | tail -n1 | sed -E 's/^#([0-9]+).*/\1/'); [[ -z "$execs" ]] && execs=0
    if [[ -n "$art" ]]; then outcome=crash; else outcome=no_crash; fi
    echo "$i,$seed,$outcome,$secs,$execs,\"$sig\",${art:+trial$i/art/$art}" >> "$out/discovery.csv"
done
first=$(ls "$out"/trial*/art/* 2>/dev/null | head -n1)
if [[ -n "$first" ]]; then
    cp "$first" "$out/first_crash.bin"
    "$bin" -minimize_crash=1 -runs=20000 -exact_artifact_path="$out/first_crash.min" "$out/first_crash.bin" > "$out/minimize.log" 2>&1 || true
fi
cat "$out/discovery.csv"
