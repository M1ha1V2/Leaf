#!/usr/bin/env bash
# Alternating order (A B, B A, ...) so a linear drift of the host cancels across pairs.
B=/root/mhajdk/bench; A=$B/leaf-baseline.jar; U=$B/uniquejar-p1.jar
for i in 1 2 3 4; do
  if [ $((i%2)) -eq 1 ]; then $B/run_bench.sh A$i $A 90 240; $B/run_bench.sh U$i $U 90 240
  else $B/run_bench.sh U$i $U 90 240; $B/run_bench.sh A$i $A 90 240; fi
done
