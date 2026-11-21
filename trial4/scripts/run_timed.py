#!/usr/bin/env python3
"""usage: run_timed.py <time_file> <cmd...>   Runs cmd, appends "wall user sys" seconds (kernel getrusage) to time_file."""
import resource, subprocess, sys, time
tf, cmd = sys.argv[1], sys.argv[2:]
t0 = time.time()
try: rc = subprocess.call(cmd)
except OSError as e: print(f"run_timed: cannot start {cmd[0]}: {e}", file=sys.stderr); rc = 127
ru = resource.getrusage(resource.RUSAGE_CHILDREN)
open(tf, "a").write(f"{time.time()-t0:.2f} {ru.ru_utime:.2f} {ru.ru_stime:.2f}\n")
sys.exit(rc if rc >= 0 else 128 - rc)
