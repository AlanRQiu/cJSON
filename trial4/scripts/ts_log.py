#!/usr/bin/env python3
"""usage: ts_log.py <target> <logdir>   (stdin = libFuzzer stderr)
Writes <logdir>/<target>.log (raw, appended) and <logdir>/<target>_timeline.csv: seconds,execs,cov_edges,features,corpus_units
for every libFuzzer progress line. Seconds are measured from the first line of this process (restarts add an offset file)."""
import pathlib, re, sys, time
t, d = sys.argv[1], pathlib.Path(sys.argv[2])
log = open(d / f"{t}.log", "a"); csvp = d / f"{t}_timeline.csv"
off = 0.0
if csvp.exists():
    rows = csvp.read_text().strip().split("\n")[1:]
    if rows: off = float(rows[-1].split(",")[0])
else:
    csvp.write_text("seconds,execs,cov_edges,features,corpus_units\n")
csv = open(csvp, "a"); t0 = time.time()
pat = re.compile(r"^#(\d+)\s+\w+\s+cov: (\d+) ft: (\d+) corp: (\d+)/")
for line in sys.stdin:
    log.write(line); log.flush()
    m = pat.match(line)
    if m: csv.write(f"{off + time.time() - t0:.1f},{m.group(1)},{m.group(2)},{m.group(3)},{m.group(4)}\n"); csv.flush()
