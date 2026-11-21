#!/usr/bin/env bash
# Replay every crashing input and the final (minimized) corpora, one process per file, and record the exit status.
# usage: bash trial4/scripts/replay.sh <label> <build_dir> <out_csv>
#   crash inputs : results/<label>/discovery_*/first_crash.* and discovery_*/trial*/art/*   -> fuzz_utils_alias
#   corpus_min   : results/<label>/corpus_min/parse -> fuzz_parse ; results/<label>/corpus_min/utils -> fuzz_utils_alias
# CSV: set,file,exit_status,signature  (exit_status 0 = clean; anything else = sanitizer abort, timeout or crash)
set -uo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; label="$1"; bd="$2"; csv="$3"; res="$here/results/$label"
export ASAN_OPTIONS=detect_leaks=1:symbolize=1 UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1
echo "set,file,exit_status,signature" > "$csv"
run() {  # run <set> <binary> <file>
    local o rc sig; o=$(timeout 20 "$2" -runs=1 "$3" 2>&1); rc=$?
    sig=$(printf '%s' "$o" | grep -m1 -E "^SUMMARY|ERROR: LeakSanitizer|runtime error" | sed 's#/[^ ]*/##; s/,/;/g')
    echo "$1,${3#$here/},$rc,\"$sig\"" >> "$csv"
}
for f in "$res"/discovery_*/first_crash.* "$res"/discovery_*/trial*/art/*; do [[ -f "$f" && "$f" != *.log ]] && run crash_inputs "$bd/fuzz_utils_alias" "$f"; done
for f in "$res"/corpus_min/parse/*; do run corpus_parse "$bd/fuzz_parse" "$f"; done
for f in "$res"/corpus_min/utils/*; do run corpus_utils "$bd/fuzz_utils_alias" "$f"; done
python3 - "$csv" <<'PY'
import csv, collections, sys
c = collections.Counter(); bad = collections.Counter()
for r in csv.DictReader(open(sys.argv[1])):
    c[r["set"]] += 1; bad[r["set"]] += r["exit_status"] != "0"
for k in c: print(f"{k}: {c[k]} inputs, {bad[k]} non-zero exits")
PY
