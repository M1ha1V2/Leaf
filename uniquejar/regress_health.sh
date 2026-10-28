#!/usr/bin/env bash
# regress_health.sh <jar> : exercises every path that changes living-entity health with assertions enabled for the entity package.
# Pass criterion: no AssertionError / "out of sync" in the log, commands accepted, server stops cleanly.
set -e; B=/root/mhajdk/bench; . $B/lib.sh
JAR=$1; D=$B/runs/regress; rm -rf $D; mkdir -p $D
cp -r $B/template/world $B/template/server.properties $B/template/eula.txt $D/; cp "$JAR" $D/server.jar
start_server $D server.jar "-ea:net.minecraft.world.entity..."
wait_for $D "Done \(" 240; sleep 20
for c in \
 "damage @e[type=minecraft:cow,limit=60] 3" \
 "effect give @e[type=minecraft:pig,limit=60] minecraft:instant_damage 1 1" \
 "effect give @e[type=minecraft:sheep,limit=60] minecraft:instant_health 1 2" \
 "effect give @e[type=minecraft:zombie,limit=40] minecraft:regeneration 20 3" \
 "effect give @e[type=minecraft:villager,limit=40] minecraft:health_boost 30 4" \
 "attribute @e[type=minecraft:cow,limit=30] minecraft:max_health base set 4" \
 "data modify entity @e[type=minecraft:zombie,limit=20,sort=random] Health set value 0.0f" \
 "data modify entity @e[type=minecraft:villager,limit=20,sort=random] Health set value 1.0f" \
 "data modify entity @e[type=minecraft:skeleton,limit=20,sort=random] Health set value 9999.0f" \
 "kill @e[type=minecraft:chicken,limit=100]" \
 "forceload remove -128 -128 127 127" ; do cmd "$c"; sleep 2; done
sleep 25; cmd "forceload add -128 -128 127 127"; sleep 40   # unload + reload chunks: entities are re-read from NBT
cmd "damage @e[type=minecraft:cow,limit=30] 2"; cmd "kill @e[type=minecraft:sheep,limit=100]"; sleep 30
cmd "stop"; wait $SERVER_PID || true
echo "accepted-command errors : $(grep -cE 'Unknown or incomplete|Incorrect argument|No entity was found' $D/console.log)"
echo "AssertionError/out-of-sync: $(grep -cE 'AssertionError|out of sync' $D/console.log)"
echo "other exceptions ticking : $(grep -c 'Exception ticking\|Ticking entity' $D/console.log)"
grep -E "Applied|Killed|Modified|Gave" $D/console.log | head -3
tail -2 $D/console.log
