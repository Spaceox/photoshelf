
# shelfrog

Organize your photos based on when it was shot (but also any other file because as a fallback it uses last modified date).

This is an old version, and won't be touched anymore. It was kept because the new version is completely different and I wanted to keep this.

**Currently works only on Windows** linux support will come shortly.

# Use

Put your files inside a folder called working (or whatever you set workingDirectory to) and run the application just outside the folder.

# Build

Just compile as any other nim application

    nim c shelfrog.nim

The release build uses these options for general optimization:

    nim c -d:release --passC:-flto --passL:-flto --opt:speed --gc:orc -d:useBranchFree64 shelfrog.nim


## Dependencies
Requires [suru](https://github.com/de-odex/suru) and [w8crc](https://github.com/sumatoshi/w8crc).

Also requires Exiftool by Phil Harvey. You can find it [here](https://exiftool.org/) or [here](http://exiftool.sourceforge.net/).
