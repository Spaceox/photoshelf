import os
import strformat
import strutils
import sugar
import w8crc
import times
import nimpy

# Lookup table for crc32
const lookup = crc32Posix.initLookup()

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

# Self-explanatory duplicate file check using CRC32 (POSIX)
# i've exported it to python in case someone wants to edit the python file and use it there but how it's made rn, it's not needed
proc crcCheck(file1: string, file2: string): bool {.exportpy.} =
    return file1.crcFromFile(crc32Posix, lookup) == file2.crcFromFile(
            crc32Posix, lookup)

# Get last modification date of a file
# why didn't i put this in the python script? oh well, i'll keep it here
proc getModDate(file: string): string {.exportpy.} =
    return format(getLastModificationTime(file), "yyyy:MM:dd")

# Creates the folder(s), manages duplicates (just renames them or moves them if they're the exact same) and moves the file
# i could just move everything in the python script, but i'm lazy and this should be a bit faster(?)
# just realized this makes it less customizable too, i'm probably the only one who will use this so ehh
proc moveFile(file: string, folder0: string, folder1: string, folder2: string,
    dupeDir: string, echoMore: bool) {.exportpy.} =

    let
        splitPath = splitFile(file)
        destDir = fmt"{folder0}/{folder1}/{folder2}"

    var
        filename = splitPath.name
        originalPath = fmt"{splitPath.dir}/{filename}{splitPath.ext}"
        destPath = fmt"{destDir}/{filename}{splitPath.ext}"

    createDir(destDir)

    while fileExists(destPath):
        if crcCheck(originalPath, destPath) and not (dupeDir in destPath):
            if echoMore: echo fmt"{originalPath} is the same as {destPath}, moving into {dupeDir}"
            destPath = fmt"{dupeDir}/{filename}{splitPath.ext}"
            continue
        else:
            if echoMore: echo fmt"{destPath} already exists, renaming to {filename}_duplicate{splitPath.ext}"
            moveFile(fmt"{originalPath}",
                fmt"{splitPath.dir}/{filename}_duplicate{splitPath.ext}")
            filename = fmt"{filename}_duplicate"
            originalPath = fmt"{splitPath.dir}/{filename}{splitPath.ext}"
            destPath = fmt"{destDir}/{filename}{splitPath.ext}"

    moveFile(originalPath, destPath)
