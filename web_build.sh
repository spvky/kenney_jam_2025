#!/bin/bash -e

# Point this to where you installed emscripten. Optional on systems that already
# have `emcc` in the path.
if [[ -z "$EMSDK" ]]; then
    EMSCRIPTEN_SDK_DIR="$HOME/emsdk"
else
    EMSCRIPTEN_SDK_DIR="$EMSDK"
fi

ODIN_BIN=${ODIN:-odin}

OUT_DIR="build/web"

mkdir -p $OUT_DIR

export EMSDK_QUIET=1
[[ -f "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh" ]] && . "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh"

# Note RAYLIB_WASM_LIB=env.o -- env.o is an internal WASM object file. You can
# see how RAYLIB_WASM_LIB is used inside <odin>/vendor/raylib/raylib.odin.
#
# The emcc call will be fed the actual raylib library file. That stuff will end
# up in env.o
#
# Note that there is a rayGUI equivalent: -define:RAYGUI_WASM_LIB=env.o
$ODIN_BIN build . -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o -out:$OUT_DIR/game.wasm.o

ODIN_PATH=$($ODIN_BIN root)

cp $ODIN_PATH/core/sys/wasm/js/odin.js $OUT_DIR

files="$OUT_DIR/game.wasm.o ${ODIN_PATH}/vendor/raylib/wasm/libraylib.a ${ODIN_PATH}/vendor/raylib/wasm/libraygui.a"

# index_template.html contains the javascript code that calls the procedures in
# source/main_web/main_web.odin
flags="-sUSE_GLFW=3 -sWASM_BIGINT -sALLOW_MEMORY_GROWTH=1 -sINITIAL_HEAP=16777216 -sSTACK_SIZE=65536 -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file index.html --preload-file assets"

# For debugging: Add `-g` to `emcc` (gives better error callstack in chrome)
emcc -o $OUT_DIR/index.html $files $flags

rm $OUT_DIR/game.wasm.o

echo "Web build created in ${OUT_DIR}"
