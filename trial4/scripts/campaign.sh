#!/usr/bin/env bash
# Sustained campaign: fuzz_parse and fuzz_utils in parallel (one core each), then corpus minimization, coverage, summary.
# usage: bash trial4/scripts/campaign.sh <label> [seconds]     e.g.  campaign.sh baseline 1800
# Results: trial4/results/<label>/ ; not bit-for-bit reproducible (libFuzzer is bounded by wall-clock time).
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; root="$(cd -- "$here/.." && pwd)"
label="${1:?usage: campaign.sh <label> [seconds]}"; secs="${2:-1800}"; res="$here/results/$label"; build="$here/build"
python3 -I "$here/scripts/make_seeds.py" >/dev/null
bash "$here/scripts/build.sh" "${SRC:-$root}"
for d in logs crashes corpus_work corpus_min coverage; do rm -rf "$res/$d"; done      # keep discovery/ if present
mkdir -p "$res/logs" "$res/crashes/parse" "$res/crashes/utils" "$res/corpus_work/parse" "$res/corpus_work/utils"
export ASAN_OPTIONS=detect_leaks=1:symbolize=1:handle_abort=1 UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1

job() {  # job <target> <seed>
    local t="$1" seed="$2" remaining="$secs" rc started now
    : > "$res/logs/${t}_time.txt"
    while (( remaining > 0 )); do
        started=$(date +%s); set +e
        python3 -I "$here/scripts/run_timed.py" "$res/logs/${t}_time.txt" "$build/fuzz_$t" -max_total_time="$remaining" \
            -seed="$seed" -dict="$root/fuzzing/json.dict" -max_len=4096 -timeout=10 -rss_limit_mb=2048 -print_final_stats=1 \
            -artifact_prefix="$res/crashes/$t/" "$res/corpus_work/$t" "$here/seeds/$t" 2>&1 \
            | python3 -I "$here/scripts/ts_log.py" "$t" "$res/logs"
        rc=${PIPESTATUS[0]}; set -e
        now=$(date +%s); remaining=$(( remaining - (now - started) )); echo "$rc" >> "$res/logs/${t}_exit.txt"
        (( rc == 0 )) && break
        if (( now - started < 2 )) || [[ -z "$(ls -A "$res/crashes/$t" 2>/dev/null)" ]]; then
            echo "ERROR: fuzz_$t exited $rc without a crash artifact; see $res/logs/$t.log" >&2; exit 1; fi
        seed=$((seed + 1))      # a crash was recorded: keep fuzzing for the rest of the budget
    done
}
echo "== fuzzing ${secs}s on 2 cores =="
job parse 4242 & p1=$!; job utils 4342 & p2=$!; fail=0; wait $p1 || fail=1; wait $p2 || fail=1
(( fail )) && { echo "ERROR: a fuzzing job failed" >&2; exit 1; }
echo "== minimizing corpora =="
for t in parse utils; do mkdir -p "$res/corpus_min/$t"
    "$build/fuzz_$t" -merge=1 "$res/corpus_min/$t" "$res/corpus_work/$t" "$here/seeds/$t" > "$res/logs/${t}_merge.log" 2>&1 || true; done
bash "$here/scripts/coverage.sh" "$label"
python3 -I "$here/scripts/summarize.py" "$label"
