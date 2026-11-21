#!/usr/bin/env python3
"""usage: uncovered.py <label>  -> coverage/uncovered_functions.csv (file,function,executions) for library functions with 0 executions."""
import csv, json, pathlib, sys
res = pathlib.Path(__file__).resolve().parent.parent / "results" / sys.argv[1] / "coverage"
d = json.loads((res / "full.json").read_text())["data"][0]
rows = []
for f in d["functions"]:
    name = pathlib.Path(f["filenames"][0]).name
    if name in ("cJSON.c", "cJSON_Utils.c") and f["count"] == 0:
        rows.append((name, f["name"], f["count"]))
rows.sort()
with open(res / "uncovered_functions.csv", "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(["file", "function", "executions"]); w.writerows(rows)
print(f"uncovered library functions: {len(rows)}")
