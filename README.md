
  

# shelfrog

Organize your photos and videos based on exif data (but also any other file because as a fallback it uses last modified date).

**Currently tested only on Windows, Linux hasn't been tested yet.**

# Use

1. Install python  
2. Download the latest release
3. Extract the zip where you want to organize your pictures
4. Open a command prompt in that folder
5. Install the dependencies with `pip install -r requirements.txt`
6. Put your files inside a folder called working (or whatever you set workingDirectory to) 
7. Run `frog.py` just outside the working folder

An all in one package should come soon-ish, when I understand how to use nuitka

# Build

First of all you should install the dependencies just below this part.

Then build the nim module as the nimpy instruction say you should (add additional switches if you want, for example `-d:useBranchFree64` speeds up w8crc processing crc32 on x64 machines)
  
    nim c --app:lib --out:shelf.pyd --threads:on --tlsEmulation:off --passL:-static shelf # windows
    nim c --app:lib --out:shelf.so --threads:on shelf # linux

The releases are compiled with:

    nim c -d:release -d:strip -d:useBranchFree64 -d:lto --opt:speed  --gc:arc  --app:lib --out:shelf.pyd --threads:on --tlsEmulation:off --passL:-static shelf #windows
    nim c -d:release -d:strip -d:useBranchFree64 -d:lto --opt:speed  --gc:arc  --app:lib --out:shelf.so --threads:on shelf #linux
  
Then you just need to run `frog.py` to run the application

## Dependencies

`shelf.nim` requires:

 - [Nim](https://nim-lang.org/)
 - [w8crc](https://github.com/sumatoshi/w8crc)
 - [nimpy](https://github.com/yglukhov/nimpy)

`frog.py` requires:

 - [Python](https://www.python.org/)
 - [rich](https://github.com/Textualize/rich)
 - [pyexiv2](https://github.com/LeoHsiao1/pyexiv2)

