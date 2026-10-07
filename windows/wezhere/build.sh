#!/usr/bin/env sh
# clang targeting MSVC ABI; needs VS + Windows SDK libs (already there).
set -e
cd "$(dirname "$0")"
mkdir -p build
clang -O2 -Wall -Wextra -o build/wezhere.exe wezhere.c \
  -Wl,/subsystem:windows -Wl,/entry:wWinMainCRTStartup \
  -lshell32 -luser32 -lole32 -loleaut32 -ltaskschd
echo "built $(pwd)/build/wezhere.exe"
