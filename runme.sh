#!/bin/bash

# Add the local Lua rocks to the Lua paths
d="$(pwd)"
new_cpath="${d}/lua-5.2/?.dll;${d}/lua-5.2/?.so;${d}/lua-5.2/loadall.dll;${d}/?.dll"
new_lpath="${d}/lua-5.2/?.lua;${d}/lua-5.2/?/init.lua;${d}/?.lua"

export LUA_CPATH="${new_cpath}${LUA_CPATH:+;${LUA_CPATH}}"
export LUA_PATH="${new_lpath}${LUA_PATH:+;${LUA_PATH}}"

# Add the local binaries to the path

new_path="${d}/bin:${d}/bin/osgPlugins-3.5.6"
export PATH="${new_path}${PATH:+:${PATH}}"

# We have to run windowed --- full-screen isn't supported yet for some reason.
export OSG_WINDOW="100 100 600 400"

# Debug info
cat <<EOF
PATH:
$PATH

LUA_PATH:
$LUA_PATH

LUA_CPATH:
$LUA_CPATH

EOF

# Fire it up!
case "$1" in
    --help) cat <<EOF
runme.sh: run lua-osg-livecoding
Options (only detected if the first parameter):
    --help              Print this help.
    -g                  Run livecoding in gdb.
    -i, --interactive   Spawn a shell instead of running livecoding.exe.
                        You can run livecoding.exe in that shell.

Any other options are passed to livecoding.exe.
EOF
            exit
            ;;
    -i|--interactive)
            export PS1="lol $PS1"
            exec "$SHELL" -i
            exit
            ;;
esac

if [[ $1 == -g ]]; then
    gdb --args "${d}/livecoding.exe" "$@"
else
    "${d}/livecoding.exe" "$@"
fi

stty sane   # just in case of an abort

# vi: set ts=4 sts=4 sw=4 et ai ff=unix: #
