#!/bin/bash

CORPUS="$1"
BASELINE="$2"
HARDENED="$3"
OUTPUT="$4"

echo "file,baseline_exit,hardened_exit" > "$OUTPUT"

for input in "$CORPUS"/*; do
    [ -f "$input" ] || continue

    timeout 2s "$BASELINE" "$input" yes >/dev/null 2>&1
    baseline_status=$?

    timeout 2s "$HARDENED" "$input" yes >/dev/null 2>&1
    hardened_status=$?

    printf '"%s",%d,%d\n' \
      "$(basename "$input")" \
      "$baseline_status" \
      "$hardened_status" >> "$OUTPUT"
done
