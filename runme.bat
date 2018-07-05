@echo off
:: runme.bat: Run lua-osg-livecoding
:: Copyright (c) 2018 cxw/Incline
::#!/bin/bash

::# Add the local Lua rocks to the Lua paths
::d="$(pwd)"
set LUA_CPATH=lua-5.2/?.dll;lua-5.2/?.so;lua-5.2/loadall.dll;?.dll
set LUA_PATH=lua/?.lua;lua-5.2/?.lua;lua-5.2/?/init.lua;?.lua

::export LUA_CPATH="${new_cpath}${LUA_CPATH:+;${LUA_CPATH}}"
::export LUA_PATH="${new_lpath}${LUA_PATH:+;${LUA_PATH}}"

::# Add the local binaries to the path

PATH %PATH%;%~dp0bin;%~dp0bin\osgPlugins-3.5.6
::export PATH="${new_path}${PATH:+:${PATH}}"

::# We have to run windowed --- full-screen isn't supported yet for some reason.
::set OSG_WINDOW="100 100 600 400"
::   This doesn't take effect for some reason.  Therefore, we use the
::   -c option below.

::# Debug info
::cat <<EOF
echo PATH:
PATH

echo LUA_PATH:
echo %LUA_PATH%

echo LUA_CPATH:
echo %LUA_CPATH%

::EOF

::# Fire it up!
::case "$1" in
::    --help) cat <<EOF
::runme.sh: run lua-osg-livecoding
::Options (only detected if the first parameter):
::    --help              Print this help.
::    -g                  Run livecoding in gdb.
::    -i, --interactive   Spawn a shell instead of running livecoding.exe.
::                        You can run livecoding.exe in that shell.

::Any other options are passed to livecoding.exe.
::EOF
::            exit
::            ;;
::    -i|--interactive)
::            export PS1="lol $PS1"
::            exec "$SHELL" -i
::            exit
::            ;;
::esac

::if [[ $1 == -g ]]; then
::    gdb --args "${d}/livecoding.exe" "$@"
::else
::    "${d}/livecoding.exe" "$@"
::fi
livecoding -c default.view %1 %2 %3 %4 %5 %6 %7 %8 %9

::stty sane   # just in case of an abort

::# vi: set ts=4 sts=4 sw=4 et ai ff=dos: #
