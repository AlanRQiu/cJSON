#!/usr/bin/env python3
"""usage: summarize.py <label> -> results/<label>/summary.csv, line_coverage.csv, coverage_over_time.png. Every number is read from raw files."""
import csv, json, pathlib, re, sys
here = pathlib.Path(__file__).resolve().parent.parent; label = sys.argv[1]; res = here / "results" / label
def cnt(d): return len([p for p in d.iterdir() if p.is_file()]) if d.exists() else 0
rows = []
for t in ("parse", "utils"):
    wall = user = sy = 0.0
    for line in (res / "logs" / f"{t}_time.txt").read_text().split("\n"):
        p = line.split()
        if len(p) == 3: wall += float(p[0]); user += float(p[1]); sy += float(p[2])
    log = (res / "logs" / f"{t}.log").read_text(errors="replace")
    m = re.search(r"stat::number_of_executed_units:\s*(\d+)", log); execs = int(m.group(1)) if m else 0
    tl = list(csv.DictReader(open(res / "logs" / f"{t}_timeline.csv"))); last = tl[-1]
    if execs <= 0 or wall <= 0: sys.exit(f"ERROR: no executions recorded for {t}")
    rows.append(dict(target=f"fuzz_{t}", wall_seconds=f"{wall:.1f}", cpu_seconds=f"{user+sy:.1f}", cpu_hours=f"{(user+sy)/3600:.3f}",
        executions=execs, final_cov_edges=last["cov_edges"], final_features=last["features"], corpus_work_units=cnt(res/"corpus_work"/t),
        corpus_min_units=cnt(res/"corpus_min"/t), crash_artifacts=cnt(res/"crashes"/t)))
with open(res / "summary.csv", "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
cs = json.loads((res / "coverage" / "summary.json").read_text())["data"][0]
files = {pathlib.Path(f["filename"]).name: f["summary"] for f in cs["files"]}
with open(res / "line_coverage.csv", "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(["file","lines_total","lines_covered","lines_percent","functions_total","functions_covered","functions_percent"])
    for n in ("cJSON.c", "cJSON_Utils.c"):
        s = files[n]; w.writerow([n, s["lines"]["count"], s["lines"]["covered"], f'{s["lines"]["percent"]:.2f}', s["functions"]["count"], s["functions"]["covered"], f'{s["functions"]["percent"]:.2f}'])
    t = cs["totals"]; w.writerow(["TOTAL", t["lines"]["count"], t["lines"]["covered"], f'{t["lines"]["percent"]:.2f}', t["functions"]["count"], t["functions"]["covered"], f'{t["functions"]["percent"]:.2f}'])
try:
    import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(7, 3.6), dpi=150)
    for t, c in (("parse", "#1f77b4"), ("utils", "#d95f02")):
        tl = list(csv.DictReader(open(res / "logs" / f"{t}_timeline.csv")))
        ax.step([float(r["seconds"]) / 60 for r in tl], [int(r["cov_edges"]) for r in tl], where="post", label=f"fuzz_{t}", color=c)
    ax.set_xlabel("Wall-clock minutes"); ax.set_ylabel("Edges covered (libFuzzer cov)"); ax.set_title(f"Coverage over time ({label})"); ax.grid(alpha=.3); ax.legend(frameon=False)
    fig.tight_layout(); fig.savefig(res / "coverage_over_time.png")
except ImportError: print("matplotlib missing: plot skipped")
for r in rows: print(r)
print("TOTAL CPU-hours:", f"{sum(float(r['cpu_hours']) for r in rows):.3f}", "| line coverage:", f'{cs["totals"]["lines"]["percent"]:.1f}%')
