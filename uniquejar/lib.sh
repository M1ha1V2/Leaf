#!/usr/bin/env bash
# Shared helpers. JVM flags are identical for every jar under test.
JVM_FLAGS="-Xms4G -Xmx4G -XX:+UseG1GC -XX:+AlwaysPreTouch -XX:MaxGCPauseMillis=200"
# start_server <dir> <jar> [extra jvm flags...]; stdin comes from <dir>/in.fifo
start_server() {
  local dir=$1 jar=$2; shift 2
  rm -f "$dir/in.fifo"; mkfifo "$dir/in.fifo"
  ( cd "$dir"; exec 3<>in.fifo
    exec java $JVM_FLAGS "$@" -Xlog:gc*:file=gc.log -jar "$jar" --nogui <&3 > console.log 2>&1 ) &
  SERVER_PID=$!
  exec 9<>"$dir/in.fifo"   # keep a writer open for the whole run
}
cmd() { echo "$1" >&9; }
wait_for() { # wait_for <dir> <regex> <timeout_s>
  for i in $(seq 1 "$3"); do grep -qE "$2" "$1/console.log" && return 0; sleep 1; done; return 1; }
