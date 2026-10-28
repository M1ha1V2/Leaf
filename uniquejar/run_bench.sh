#!/usr/bin/env bash
# run_bench.sh <label> <jar> [warmup_s=120] [measure_s=300]
# Same world template, same properties, same JVM flags; only the jar differs.
set -e; B=/root/mhajdk/bench; . $B/lib.sh
LABEL=$1; JAR=$2; WARM=${3:-120}; MEAS=${4:-300}
D=$B/runs/$LABEL; rm -rf $D; mkdir -p $D
cp -r $B/template/world $B/template/cache $B/template/server.properties $B/template/eula.txt $D/; cp "$JAR" $D/server.jar
start_server $D server.jar -XX:StartFlightRecording=filename=$D/rec.jfr,settings=profile
wait_for $D "Done \(" 240
sleep $WARM
n=$((MEAS/10)); for i in $(seq 1 $n); do cmd "tick query"; sleep 10; done
cmd "stop"; wait $SERVER_PID || true
echo "$LABEL done: $(grep -c 'Average time per tick' $D/console.log) tick samples"
