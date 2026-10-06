# Emscripten build of NarutoSenki-V2 (cocos2d-x 2.2.6 fork) using the Lua 5.1
# wasm library and platform conventions from cocos2d-x-wasm.
# Source lists come from the repo's own proj.linux Makefiles.
cmake_minimum_required(VERSION 3.13)
project(NarutoSenki C CXX)

set(NS_ROOT "" CACHE PATH "NarutoSenki-V2 checkout")
set(CCWASM_EXTERNAL "" CACHE PATH "cocos2d-x-wasm external/ checkout")
set(WEB_SHELL "${CMAKE_CURRENT_SOURCE_DIR}/shell.html" CACHE FILEPATH "Emscripten shell")

# Collect SOURCES from a proj.linux Makefile, paths made absolute.
function(mk_sources out dir)
  file(READ "${dir}/Makefile" mk)
  string(REGEX REPLACE "\\\\[ \t\r]*\n" " " mk "${mk}")
  string(REGEX MATCH "\nSOURCES[ \t]*=[^\n]*" line "\n${mk}")
  string(REGEX MATCHALL "[^ \t\r]+\\.(cpp|c)" items "${line}")
  set(res)
  foreach(i IN LISTS items)
    get_filename_component(p "${dir}/${i}" ABSOLUTE)
    list(APPEND res "${p}")
  endforeach()
  set(${out} ${res} PARENT_SCOPE)
endfunction()

mk_sources(SRC_COCOS  ${NS_ROOT}/cocos2dx/proj.linux)
mk_sources(SRC_AUDIO  ${NS_ROOT}/CocosDenshion/proj.linux)
mk_sources(SRC_EXT    ${NS_ROOT}/extensions/proj.linux)
mk_sources(SRC_LUA    ${NS_ROOT}/scripting/lua/proj.linux)
mk_sources(SRC_GAME   ${NS_ROOT}/projects/NarutoSenki/proj.linux)

set(PORTS "SHELL:-s USE_LIBPNG=1" "SHELL:-s USE_LIBJPEG=1" "SHELL:-s USE_ZLIB=1"
          "SHELL:-s USE_OGG=1" "SHELL:-s USE_VORBIS=1")

# luaL_reg: LuaJIT-2.0 alias missing from cocos2d-x-wasm's Lua headers
add_compile_definitions(LINUX NDEBUG luaL_reg=luaL_Reg SQLITE_THREADSAFE=0)
# The 2.2 tree carries stale Zynga-era `#ifdef EMSCRIPTEN` paths (SDL image
# loading etc.); build the tested Linux paths instead.
add_compile_options(-UEMSCRIPTEN ${PORTS} -O2 -Wno-everything)
set(CMAKE_CXX_STANDARD 20)

include_directories(
  ${CMAKE_CURRENT_SOURCE_DIR}/shim
  ${NS_ROOT}/cocos2dx
  ${NS_ROOT}/cocos2dx/cocoa
  ${NS_ROOT}/cocos2dx/include
  ${NS_ROOT}/cocos2dx/kazmath/include
  ${NS_ROOT}/cocos2dx/platform/linux
  ${NS_ROOT}/cocos2dx/platform/third_party/linux/libtiff/include
  ${NS_ROOT}/cocos2dx/platform/third_party/linux/libwebp
  ${NS_ROOT}/CocosDenshion/include
  ${NS_ROOT}/extensions
  ${NS_ROOT}/extensions/GUI/CCControlExtension
  ${NS_ROOT}/extensions/GUI/CCEditBox
  ${NS_ROOT}/extensions/CocoStudio/Armature
  ${NS_ROOT}/extensions/CocoStudio/GUI
  ${NS_ROOT}/external
  ${NS_ROOT}/external/sqlite3/include
  ${NS_ROOT}/scripting/lua
  ${NS_ROOT}/scripting/lua/tolua
  ${NS_ROOT}/scripting/lua/xxtea
  ${NS_ROOT}/scripting/lua/cocos2dx_support
  ${CCWASM_EXTERNAL}/lua/luajit/include
  ${NS_ROOT}/projects/NarutoSenki
  ${NS_ROOT}/projects/NarutoSenki/Classes
  ${NS_ROOT}/projects/NarutoSenki/Classes/Core
)

add_executable(NarutoSenki
  ${SRC_COCOS} ${SRC_AUDIO} ${SRC_EXT} ${SRC_LUA} ${SRC_GAME}
  ${NS_ROOT}/external/sqlite3/src/sqlite3.c
  ${CMAKE_CURRENT_SOURCE_DIR}/shim/stubs.c)

set(DATA_ROOT ${NS_ROOT}/projects/NarutoSenki)
target_link_options(NarutoSenki PRIVATE ${PORTS} -O2
  "SHELL:-s USE_GLFW=3" "SHELL:-s FULL_ES2=1" "SHELL:-s ALLOW_MEMORY_GROWTH=1"
  "SHELL:-s INITIAL_MEMORY=256MB" "SHELL:-s FORCE_FILESYSTEM=1"
  -lopenal -lidbfs.js
  "SHELL:--shell-file ${WEB_SHELL}"
  "SHELL:--preload-file ${DATA_ROOT}/Resources@/Resources"
  "SHELL:--preload-file ${DATA_ROOT}/lua@/lua")
target_link_libraries(NarutoSenki ${CCWASM_EXTERNAL}/lua/luajit/prebuilt/emscripten/liblua.a)
set_target_properties(NarutoSenki PROPERTIES OUTPUT_NAME index SUFFIX ".html")
