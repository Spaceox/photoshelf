
# shelfrog

Organize your photos and videos based on exif data (but also any other file because as a fallback it uses last modified date).

**Currently tested only on Windows and Linux (specifically Ubuntu (Preview) on WSL).**

# Use

1. Install python  
2. Download the latest release
3. Extract the zip where you want to organize your pictures
4. Open a command prompt in that folder
5. Install the dependencies with `pip install -r requirements.txt`
6. Put your files inside a folder called working (or whatever you set workingDirectory to) 
7. Run `frog.py` just outside the working folder


# Build

## Semi-automatically
1. Install nim (python insn't needed for the build but for the execution)  
2. Download the repo
3. Run `chmod +x reqinstall.sh` and `reqinstall.sh` (this is only needed the first time to install the requirements)  
**Note: this script works only on Ubuntu (and probably other debian-based distros)**  
4. Finally start `chmod +x build.sh` and `build.sh`  

## Manually

First of all you should install the dependencies just below this part.

Then build the nim module as the nimpy instruction say you should (add additional switches if you want, for example `-d:lto` creates smaller files)
  
    nim c --app:lib --out:shelf.pyd shelf # windows
    nim c --app:lib --out:shelf.so shelf # linux

The releases are compiled with (remove `-d:mingw` if compiling on windows instad of linux):

    nim c --cpu:amd64 -d:mingw -d:release -d:strip -d:lto --opt:speed --gc:orc --app:lib --out:shelf.pyd shelf #windows
    nim c --cpu:amd64 --os:linux -d:release -d:strip -d:lto --opt:speed --gc:orc --app:lib --out:shelf.so shelf #linux
  
Then you just need to run `frog.py` to run the application

## Dependencies

`shelf.nim` requires:

 - [Nim](https://nim-lang.org/)
 - [crc32](https://github.com/juancarlospaco/nim-crc32)
 - [nimpy](https://github.com/yglukhov/nimpy)

`frog.py` requires:

 - [Python](https://www.python.org/)
 - [rich](https://github.com/Textualize/rich)
 - [pyexiv2](https://github.com/LeoHsiao1/pyexiv2)

