import os
import strformat
import strutils
import osproc
import suru
import sugar
import w8crc
import times

# Directory names
const workingDirectory: string = "working/"
const duplicatesDirectory: string = "dupes/"

# Lookup table for crc32
const lookup = crc32Posix.initLookup()

# Self-explanatory duplicate file check using crc
proc crcCheck(file1: string, file2: string): bool =
    return file1.crcFromFile(crc32Posix, lookup) == file2.crcFromFile(
            crc32Posix, lookup)

# Add quotes to a string (generally path) so it works better with exiftool
proc quotify(str: string): string =
    return "\u0022" & str & "\u0022"

# Gets original time/date or last modified time/date
proc getTimeDate(path: string): seq[string] =
    var exif: string = execProcess(fmt"exiftool.exe -T -d %Y-%m-%d -q -q -m -p '$datetimeoriginal' {quotify(path)}")
    if exif == "\'-\'\n" or "Error" in exif:
        echo fmt"Original time/date doesn't exist in {path}, using file modified date/time."
        let fileInfo = getLastModificationTime(path)
        exif = format(fileInfo, "yyyy-MM-dd")
    return exif.replace("'", "").replace("\n", "").split('-')

# Prepares everything for final move
proc finalDestination(timedate: seq[string], path: string): tuple[
        src: string, dest: string] =
    let splitFile = splitFile(path)
    var filename = splitFile.name
    let destDir = fmt"{timedate[0]}/{timedate[1]}/{timedate[2]}"
    createDir(destDir)

    while fileExists(fmt"{destDir}/{filename}{splitFile.ext}"):
        if crcCheck(fmt"{destDir}/{filename}{splitFile.ext}",
                fmt"{splitFile.dir}/{filename}{splitFile.ext}"):

            echo fmt"{destDir}/{filename}{splitFile.ext} is the same as {splitFile.dir}/{filename}{splitFile.ext}, moving into {duplicatesDirectory}"

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
    if "Thumbs.db" in image or "ZbThumbnail.info" in image or ".json" in image:
        echo fmt"Skipping {image}"
        continue
    #let timedate = getTimeDate("\u0022" & absolutePath(image) & "\u0022")
    let timedate = getTimeDate(image)
    let final: tuple[src: string, dest: string] = finalDestination(timedate, image)
    moveFile(final.src, final.dest)
    inc bar
    bar.update()

bar.finish()

