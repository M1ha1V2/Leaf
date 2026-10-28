#!/usr/bin/env bash
# Builds the reproducible world template: fixed seed, forceloaded 16x16 chunk area, deterministic entity population.
set -e; B=/root/mhajdk/bench; . $B/lib.sh
JAR=${1:?jar}; D=$B/template; rm -rf $D; mkdir -p $D; cp "$JAR" $D/server.jar; echo eula=true > $D/eula.txt
cat > $D/server.properties <<P
online-mode=false
level-seed=1337uniquejar
level-type=minecraft\:normal
view-distance=8
simulation-distance=8
spawn-monsters=true
enable-command-block=true
max-tick-time=-1
sync-chunk-writes=false
P
start_server $D server.jar
wait_for $D "Done \(" 240
cmd "forceload add -128 -128 127 127"
python3 -I - <<PY > $D/populate.txt
import random
r=random.Random(42)
mix=[("cow",600,""),("sheep",400,""),("pig",300,""),("chicken",400,""),("villager",300,""),
     ("zombie",150,"{PersistenceRequired:1b}"),("skeleton",100,"{PersistenceRequired:1b}"),("item",600,"{Item:{id:\"minecraft:cobblestone\",count:1}}")]
for name,n,nbt in mix:
    for _ in range(n):
        print(f"execute positioned {r.randint(-120,120)} 0 {r.randint(-120,120)} positioned over motion_blocking run summon minecraft:{name} ~ ~ ~ {nbt}".rstrip())
PY
sleep 60   # let forced chunks generate
while read -r l; do cmd "$l"; done < $D/populate.txt
sleep 20; cmd "save-all flush"; wait_for $D "Saved the game|ThreadedAnvilChunkStorage|Saved" 120 || true; sleep 5
cmd "stop"; wait $SERVER_PID || true
grep -c "Unknown\|Incorrect" $D/console.log || true
du -sh $D/world
