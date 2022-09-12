import os
import strformat
import sugar
import strutils
#import w8crc
import crc32
import times
import nimpy

# Lookup table for crc32
#const lookup = crc32Posix.initLookup()

# echoMore? (aka printMore)
var echoMore: bool

# Sets echoMore from python
proc setEchoMore(printMore: bool): void {.exportpy.} =
    echoMore = printMore

# Nicer log
proc niceishLogText(text: string): void {.exportpy.} =
    if echoMore: echo "\u001b[2m[" & getTime().format("HH:mm:ss") &
            "]\u001b[0m\u001b[93m " & text & "\u001b[0m"

# Get list of files in folder and quit if workdir doesn't exist or is empty
proc getFiles(workDir: string, dupeDir: string): seq {.exportpy.} =

    if dirExists(workDir) != true:
        echo fmt"Cannot find working directory, make sure it's '{workDir}'. Exiting..."
        quit(QuitFailure)

    createDir(dupeDir)

    let files = collect(newSeq):
        for file in walkDirRec(workdir):
            file

    if len(files) == 0:
        echo fmt"{workDir} is empty. Exiting..."
        quit(QuitFailure)
    else:
        return files

# Get last modification date of a file
# why didn't i put this in the python script? oh well, i'll keep it here
proc getModDate(file: string): string {.exportpy.} =
    return format(getLastModificationTime(file), "yyyy:MM:dd")

# Creates the folder(s), manages duplicates (just renames them or moves them if they're the exact same) and moves the file
# i could just move everything in the python script, but i'm lazy and this should be a bit faster(?)
# just realized this makes it less customizable too, i'm probably the only one who will use this so ehh
proc moveFile(file: string, folder0: string, folder1: string, folder2: string,
    dupeDir: string) {.exportpy.} =

    let
        splitPath = splitFile(file)
        destDir = fmt"{folder0}/{folder1}/{folder2}"

    var
        filename = splitPath.name
        originalPath = fmt"{splitPath.dir}/{filename}{splitPath.ext}"
        destPath = fmt"{destDir}/{filename}{splitPath.ext}"

    createDir(destDir)
    let file1crc = originalPath.dup(crc32FromFile) #.crcFromFile(crc32Posix, lookup).int64.toHex(8)
    niceishLogText(fmt"Source file CRC is {file1crc}")

    while fileExists(destPath):
        let file2crc = destPath.dup(crc32FromFile) #.crcFromFile(crc32Posix, lookup).int64.toHex(8)
        niceishLogText(fmt"Destination file CRC is {file2crc}")
        if not (dupeDir in destPath) and file1crc == file2crc:
            niceishLogText(fmt"{originalPath} is the same as {destPath}, moving into {dupeDir}")
            destPath = fmt"{dupeDir}/{filename}{splitPath.ext}"
        else:
            niceishLogText(fmt"{destPath} already exists, renaming to {filename}_duplicate{splitPath.ext}")
            moveFile(fmt"{originalPath}",
                fmt"{splitPath.dir}/{filename}_duplicate{splitPath.ext}")
            filename = fmt"{filename}_duplicate"
            originalPath = fmt"{splitPath.dir}/{filename}{splitPath.ext}"
            destPath = fmt"{destDir}/{filename}{splitPath.ext}"

    moveFile(originalPath, destPath)
