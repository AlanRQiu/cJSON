#!/usr/bin/env bash
# Replay corpus_min on the coverage builds (no sanitizers) and report line/function coverage with llvm-cov.
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; res="$here/results/$1"; build="$here/build"; cov="$res/coverage"
mkdir -p "$cov/raw"; rm -f "$cov"/raw/*
for t in parse utils; do
    LLVM_PROFILE_FILE="$cov/raw/$t.profraw" "$build/cov_$t" -runs=0 "$res/corpus_min/$t" > "$cov/replay_$t.log" 2>&1
done
llvm-profdata-18 merge -sparse "$cov"/raw/*.profraw -o "$cov/all.profdata"
args=(-instr-profile="$cov/all.profdata" "$build/cov_parse" -object "$build/cov_utils" --sources "$here/../cJSON.c" "$here/../cJSON_Utils.c")
llvm-cov-18 report "${args[@]}" > "$cov/report.txt"
llvm-cov-18 export -summary-only "${args[@]}" > "$cov/summary.json"
llvm-cov-18 export "${args[@]}" > "$cov/full.json"
python3 -I "$here/scripts/uncovered.py" "$1"
