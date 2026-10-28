#!/usr/bin/env python3
"""analyze.py <run_dir>...  -> per-run mean of /tick query samples (mean, P50, P95, P99) + GC pause stats."""
import re, sys, statistics as st
for d in sys.argv[1:]:
    t = open(f"{d}/console.log", errors="replace").read()
    avg = [float(x) for x in re.findall(r"Average time per tick: ([\d.]+)ms", t)]
    p = re.findall(r"P50: ([\d.]+)ms P95: ([\d.]+)ms P99: ([\d.]+)ms", t)
    p50, p95, p99 = ([float(x[i]) for x in p] for i in range(3))
    gc = [float(x) for x in re.findall(r"Pause (?:Young|Full|Remark|Cleanup)[^\n]*? ([\d.]+)ms", open(f"{d}/gc.log").read())]
    f = lambda v: f"{st.mean(v):6.2f}" if v else "   n/a"
    print(f"{d.split('/')[-1]:8s} n={len(avg):2d} mean={f(avg)} p50={f(p50)} p95={f(p95)} p99={f(p99)} ms | gc pauses={len(gc)} max={max(gc) if gc else 0:.1f}ms sum={sum(gc):.0f}ms")
