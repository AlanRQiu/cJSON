#!/bin/bash

STATS="$1"
OUTPUT="$2"

echo "timestamp,run_time,execs_done,execs_per_sec,corpus_count,bitmap_cvg,saved_crashes,saved_hangs" > "$OUTPUT"

while true; do
    if [ -f "$STATS" ]; then
        timestamp=$(date -Is)
        run_time=$(awk -F' *: *' '$1=="run_time"{print $2}' "$STATS")
        execs=$(awk -F' *: *' '$1=="execs_done"{print $2}' "$STATS")
        eps=$(awk -F' *: *' '$1=="execs_per_sec"{print $2}' "$STATS")
        corpus=$(awk -F' *: *' '$1=="corpus_count"{print $2}' "$STATS")
        coverage=$(awk -F' *: *' '$1=="bitmap_cvg"{print $2}' "$STATS")
        crashes=$(awk -F' *: *' '$1=="saved_crashes"{print $2}' "$STATS")
        hangs=$(awk -F' *: *' '$1=="saved_hangs"{print $2}' "$STATS")

        echo "$timestamp,$run_time,$execs,$eps,$corpus,$coverage,$crashes,$hangs" >> "$OUTPUT"
    fi

    sleep 300
done
