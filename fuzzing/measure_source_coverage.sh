#!/bin/bash
# Source-level llvm-cov coverage of cJSON.c for an AFL++ queue replayed through fuzzing/afl.c.
# Usage (from repo root): fuzzing/measure_source_coverage.sh <queue_dir> <out_dir> <name>
# Writes <out_dir>/<name>.profdata, report.txt, show.txt, uncovered_functions.txt

set -euo pipefail

QUEUE="$1"
OUT="$2"
NAME="$3"

LLVM=/usr/lib/llvm-17/bin
BIN=/tmp/afl-cov
PROF=/tmp/prof-"$NAME"

rm -rf "$BIN" "$PROF"
mkdir -p "$PROF" "$OUT"

"$LLVM"/clang -O0 -fprofile-instr-generate -fcoverage-mapping cJSON.c fuzzing/afl.c -lm -o "$BIN"

count=0
for input in "$QUEUE"/id:*; do
    [ -f "$input" ] || continue
    count=$((count + 1))
    # afl.c returns nonzero for <2-byte inputs or print failures; that is not a replay error
    LLVM_PROFILE_FILE="$PROF/$count.profraw" timeout 10s "$BIN" "$input" yes >/dev/null 2>&1 || true
done
echo "Replayed inputs: $count"

"$LLVM"/llvm-profdata merge -sparse "$PROF"/*.profraw -o "$OUT/$NAME.profdata"

"$LLVM"/llvm-cov report "$BIN" -instr-profile="$OUT/$NAME.profdata" cJSON.c > "$OUT/report.txt"
"$LLVM"/llvm-cov show "$BIN" -instr-profile="$OUT/$NAME.profdata" -show-branches=count cJSON.c > "$OUT/show.txt"

# Function rows from -show-functions: Name Regions Miss Cover Lines Miss Cover Branches Miss Cover;
# a function never executed has every region missed (Regions == Miss, Cover 0.00%).
"$LLVM"/llvm-cov report "$BIN" -instr-profile="$OUT/$NAME.profdata" -show-functions cJSON.c \
    | awk 'NF >= 10 && $2 ~ /^[0-9]+$/ && $2 > 0 && $2 == $3 { print $1 }' > "$OUT/uncovered_functions.txt"

rm -rf "$BIN" "$PROF"
