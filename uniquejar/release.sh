#!/usr/bin/env bash
# UniqueJar release build: reproducible build + smoke test + provenance.
# Usage: uniquejar/release.sh <build-number>
# Output: dist/uniquejar-<mc>-b<N>.jar, .sha256, .buildinfo   (nothing is claimed unless the step ran)
set -euo pipefail
N=${1:?build number}
ROOT=$(cd "$(dirname "$0")/.." && pwd); cd "$ROOT"
MC=$(sed -n 's/^mcVersion=//p' gradle.properties)
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "ERROR: working tree has uncommitted changes to tracked files"; exit 1; }
REV=$(git rev-parse HEAD)
echo "== applying patches + building (BUILD_NUMBER=$N, MC $MC, rev ${REV:0:8})"
export BUILD_NUMBER=$N
# Two separate invocations, as documented in Leaf's README (one invocation trips Gradle's implicit-dependency validation).
{ ./gradlew --console=plain applyAllPatches && ./gradlew --console=plain createPaperclipJar; } > build-release.log 2>&1 || { tail -30 build-release.log; exit 1; }
JAR=$(ls leaf-server/build/libs/*paperclip*"build.$N"*.jar 2>/dev/null | head -1)
[ -n "$JAR" ] || { echo "ERROR: paperclip jar for build $N not found"; ls leaf-server/build/libs; exit 1; }
OUT=dist; mkdir -p $OUT; DEST=$OUT/uniquejar-$MC-b$N.jar; cp "$JAR" "$DEST"
echo "== smoke test: boot, 'version', clean stop"
T=$(mktemp -d); cp "$DEST" $T/server.jar; echo eula=true > $T/eula.txt; printf 'online-mode=false\nlevel-seed=1\nview-distance=4\nsimulation-distance=4\n' > $T/server.properties
mkfifo $T/in; ( cd $T; exec 3<>in; timeout 300 java -Xmx2G -ea:net.minecraft.world.entity... -jar server.jar --nogui <&3 > console.log 2>&1 ) & SP=$!
exec 9<>$T/in
for i in $(seq 1 240); do grep -q "Done (" $T/console.log 2>/dev/null && break; sleep 1; done
grep -q "Done (" $T/console.log || { echo "ERROR: server did not reach Done"; tail -20 $T/console.log; kill $SP 2>/dev/null; exit 1; }
echo version >&9; sleep 3; echo stop >&9; wait $SP || true
grep -E "This server is running" $T/console.log
if grep -qE "AssertionError|Exception ticking" $T/console.log; then echo "ERROR: assertion/tick exception in smoke test"; exit 1; fi
grep -q "All dimensions are saved" $T/console.log || { echo "ERROR: unclean shutdown"; exit 1; }
sha256sum "$DEST" | tee "$DEST.sha256"
{ echo "jar=$(basename $DEST)"; echo "sha256=$(sha256sum "$DEST" | cut -d' ' -f1)"; echo "source_rev=$REV"; echo "branch=$(git rev-parse --abbrev-ref HEAD)"
  echo "mc=$MC"; echo "build_number=$N"; echo "built_utc=$(date -u +%FT%TZ)"; echo "jdk=$(java -version 2>&1 | head -1)"
  echo "uniquejar_patches=$(ls leaf-server/minecraft-patches/features | grep -ci uniquejar)"; echo "license=GPL-3.0-only (binary); see LICENSE.md and licenses/"; } > "$DEST.buildinfo"
cat "$DEST.buildinfo"; echo "OK: $DEST"
