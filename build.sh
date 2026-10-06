#!/usr/bin/env bash
# Build NarutoSenki-V2 for the browser (WebAssembly + WebGL).
#
# The game ships its own cocos2d-x 2.2.6 fork (LuaJIT, tolua++ 2.x bindings),
# which is API-incompatible with cocos2d-x-wasm (3.17). So the game's engine is
# kept and compiled through its Linux/GLFW platform layer, with these pieces
# taken from cocos2d-x-wasm:
#   - the Lua 5.1 wasm library + headers it builds against (external/lua/luajit)
#   - the browser main loop, IDBFS writable path and canvas text rendering,
#     ported into naruto-senki-web.patch
#
# Usage:   ./build.sh            -> dist/index.{html,js,wasm,data}
#          python3 -m http.server -d dist 8080
# Env:     WORK=dir  OUT=dir  JOBS=n  DEBUG=1 (keeps CCLOG / Lua print output)
#          NS_REF / CCW_REF to build other commits, EMSDK_VERSION to change emsdk
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORK=${WORK:-$HERE/work}
OUT=${OUT:-$HERE/dist}
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 4)}

# emscripten version cocos2d-x-wasm recommends (its liblua.a is built with 2.0.x)
EMSDK_VERSION=${EMSDK_VERSION:-2.0.34}
NS_REPO=https://github.com/Zx-Akito/NarutoSenki-V2.git
NS_REF=${NS_REF:-ed4009cf443b82899bb0af0e20e3df97d16995d8}
CCW_REPO=https://github.com/szllzs/cocos2d-x-wasm.git
CCW_REF=${CCW_REF:-ddd7412202d6e32d446e0263e93be9f1315148f2}

NS=$WORK/NarutoSenki-V2
CCW=$WORK/cocos2d-x-wasm
EXT=$WORK/cocos2d-x-wasm-external

log() { printf '\n==> %s\n' "$*"; }

# fetch DIR URL REF [sparse patterns...]: shallow, blobless, optionally sparse
fetch() {
	local dir=$1 url=$2 ref=$3
	shift 3
	if [ "$(git -C "$dir" rev-parse -q --verify HEAD 2>/dev/null)" = "$ref" ]; then
		return
	fi
	[ -d "$dir/.git" ] || { git init -q "$dir" && git -C "$dir" remote add origin "$url"; }
	if [ $# -gt 0 ]; then
		git -C "$dir" config core.sparseCheckout true
		printf '%s\n' "$@" >"$dir/.git/info/sparse-checkout"
	fi
	git -C "$dir" fetch -q --depth 1 --filter=blob:none origin "$ref"
	git -C "$dir" checkout -q --force FETCH_HEAD
}

mkdir -p "$WORK"

# --- emsdk -------------------------------------------------------------------
if ! command -v emcc >/dev/null 2>&1 || ! emcc --version | head -1 | grep -qF " $EMSDK_VERSION "; then
	log "emsdk $EMSDK_VERSION"
	[ -d "$WORK/emsdk" ] || git clone -q --depth 1 https://github.com/emscripten-core/emsdk.git "$WORK/emsdk"
	"$WORK/emsdk/emsdk" install "$EMSDK_VERSION"
	"$WORK/emsdk/emsdk" activate "$EMSDK_VERSION" >/dev/null
	# shellcheck disable=SC1091
	source "$WORK/emsdk/emsdk_env.sh" >/dev/null 2>&1
fi
emcc --version | head -1

# --- sources -----------------------------------------------------------------
log "NarutoSenki-V2 @ $NS_REF"
fetch "$NS" "$NS_REPO" "$NS_REF" \
	'/*' '!/Doc/' '!/tools/' '!/scripting/lua/luajit/' \
	'!/projects/NarutoSenki/proj.*/' '/projects/NarutoSenki/proj.linux/' \
	'!/cocos2dx/platform/third_party/' \
	'/cocos2dx/platform/third_party/linux/libtiff/include/' \
	'/cocos2dx/platform/third_party/linux/libwebp/'

log "cocos2d-x-wasm @ $CCW_REF (Lua wasm lib from its external/ submodule)"
fetch "$CCW" "$CCW_REPO" "$CCW_REF" '/.gitmodules'
EXT_REF=$(git -C "$CCW" ls-tree HEAD external | awk '{print $3}')
EXT_URL=$(git -C "$CCW" config -f .gitmodules submodule.external.url)
fetch "$EXT" "$EXT_URL" "$EXT_REF" '/lua/luajit/include/' '/lua/luajit/prebuilt/emscripten/'

log "patch"
if git -C "$NS" apply --reverse --check "$HERE/naruto-senki-web.patch" 2>/dev/null; then
	echo "already applied"
else
	git -C "$NS" apply "$HERE/naruto-senki-web.patch"
fi

# --- build -------------------------------------------------------------------
log "build"
GEN="Unix Makefiles"
command -v ninja >/dev/null 2>&1 && GEN=Ninja
FLAGS=""
[ "${DEBUG:-0}" = 1 ] && FLAGS="-DCOCOS2D_DEBUG=1"
emcmake cmake -S "$HERE" -B "$WORK/build" -G "$GEN" \
	-DNS_ROOT="$NS" -DCCWASM_EXTERNAL="$EXT" \
	-DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" >/dev/null
cmake --build "$WORK/build" -j "$JOBS"

mkdir -p "$OUT"
cp "$WORK/build"/index.html "$WORK/build"/index.js "$WORK/build"/index.wasm "$WORK/build"/index.data "$OUT"/
log "done: $OUT"
ls -lh "$OUT"
echo "serve it, e.g.: python3 -m http.server -d \"$OUT\" 8080"
