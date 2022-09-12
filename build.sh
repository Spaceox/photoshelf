#!/bin/bash
# Compile nim for windows x64
# mental note: "--threads:on --tlsEmulation:off --passL:-static" is needed when compiling with threads:on on windows, linux only needs --threads:on
nim c --cpu:amd64 -d:mingw -d:release -d:strip -d:lto --opt:speed --gc:orc --app:lib --out:shelf.pyd shelf

# Compile for linux x64
nim c --cpu:amd64 --os:linux -d:release -d:strip -d:lto --opt:speed --gc:orc --app:lib --out:shelf.so shelf

# Zippin' them up
zip shelfrog_x64-windows.zip shelf.pyd frog.py requirements.txt
zip shelfrog_x64-linux.zip shelf.so frog.py requirements.txt
