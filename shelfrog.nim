import os
import strformat
import strutils
import osproc
import suru
import sugar
import w8crc

const workingDirectory: string = "working/"
const unknownDirectory: string = "unknown/"
const duplicatesDirectory: string = "dupes/"
const lookup = crc32Posix.initLookup()

# Gets original time/date or last modified time/date
proc getTimeDate(path: string): seq[string] =
    var exif: string = execProcess(fmt"exiftool.exe -T -d %Y-%m-%d -q -q -m -p '$datetimeoriginal' {path}")
    if exif == "\'-\'\n" or "Error" in exif:
        echo "Cannot find original date/time in exif metadata, using file modified date/time."
        exif = execProcess(fmt"exiftool.exe -T -d %Y-%m-%d -q -q -m -p '$filemodifydate' {path}")
        if exif == "\'-\'\n" or "Error" in exif:
            echo fmt"Couldn't get date/time, moving into \'{unknownDirectory}\'"
            return @["unknown"]
    return exif.replace("'", "").replace("\n", "").split('-')

proc crcCheck(file1: string, file2: string): bool =
    let file1CRC = absolutePath(file1).crcFromFile(crc32Posix, lookup)
    let file2CRC = absolutePath(file2).crcFromFile(crc32Posix, lookup)
    if file1CRC == file2CRC: return true else: return false

# Prepares everything for final move
proc finalDestination(timedate: seq[string], path: string): tuple[
        src: string, dest: string] =
    let splitFile = splitFile(path)
    var filename = splitFile.name
    let destDir = if timedate[0] == "unknown": unknownDirectory else: fmt"{timedate[0]}/{timedate[1]}/{timedate[2]}"
    createDir(destDir)

    while fileExists(fmt"{destDir}/{filename}{splitFile.ext}"):
        if crcCheck(fmt"{destDir}/{filename}{splitFile.ext}",
                fmt"{splitFile.dir}/{filename}{splitFile.ext}"):

            echo fmt"{destDir}/{filename}{splitFile.ext} is the same as {splitFile.dir}/{filename}{splitFile.ext}, moving into {duplicatesDirectory}"
            createDir(duplicatesDirectory)
            return (src: fmt"{splitFile.dir}/{filename}{splitFile.ext}",
            dest: fmt"{duplicatesDirectory}/{filename}{splitFile.ext}")
        else:
            echo fmt"{destDir}/{filename}{splitFile.ext} already exists (possible duplicate?), renaming to {filename}_duplicate{splitFile.ext}"
            let oldfilename = filename
            filename = fmt"{filename}_duplicate"

            moveFile(fmt"{splitFile.dir}/{oldfilename}{splitFile.ext}",
                    fmt"{splitFile.dir}/{filename}{splitFile.ext}")

    return (src: fmt"{splitFile.dir}/{filename}{splitFile.ext}",
            dest: fmt"{destDir}/{filename}{splitFile.ext}")

if dirExists(workingDirectory) != true:
    echo fmt"Cannot find working directory, make sure it's '{workingDirectory}'. Exiting..."
    quit(QuitFailure)

if fileExists("exiftool.exe") != true:
    echo "Cannot find exiftool.exe. Exiting..."
    quit(QuitFailure)

let files = collect(newSeq):
    for file in walkDirRec(workingDirectory):
        file

let lenfif = len(files)

if lenfif == 0:
    echo fmt"{workingDirectory} is empty. Exiting..."
    quit(QuitFailure)

var bar: SuruBar = initSuruBar()
bar[0].total = lenfif # number of iterations
bar.setup()

for image in files:
    if image == workingDirectory & "Thumbs.db":
        echo "Skipping Thumbs.db"
        continue
    let timedate = getTimeDate("\u0022" & absolutePath(image) & "\u0022")
    let final: tuple[src: string, dest: string] = finalDestination(timedate, image)
    moveFile(final.src, final.dest)
    inc bar
    bar.update()

bar.finish()

