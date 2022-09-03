import os
from strformat import fmt

import strutils
import osproc

const workingDirectory: string = "working/"

proc getShotDate(path: string): seq[string] =
    var exif: string = execProcess(fmt"exiftool.exe -T -d %Y-%m-%d-%H-%M-%S -q -q -m -p '$datetimeoriginal' {path}")
    return exif.replace("'", "").replace("\n", "").split('-')

for image in walkDirRec(workingDirectory):
    var pathsplit = splitFile(image)
    var filename = pathsplit.name
    var splitExif = getShotDate(image)
    var destDir = fmt"{splitExif[0]}/{splitExif[1]}/{splitExif[2]}"

    createDir(destDir)

    while fileExists(fmt"{destDir}/{filename}{pathsplit.ext}"):
        echo fmt"{destDir}/{filename}{pathsplit.ext} already exists (possible duplicate?), renaming to {filename}_duplicate{pathsplit.ext}"
        filename = fmt"{filename}_duplicate"

        moveFile(fmt"{workingDirectory}/{pathsplit.name}{pathsplit.ext}",
                fmt"{workingDirectory}/{filename}{pathsplit.ext}")

    moveFile(fmt"{workingDirectory}/{filename}{pathsplit.ext}",
            fmt"{destDir}/{filename}{pathsplit.ext}")


#[

let db = openDatabase("organize.db")

db.execScript("""
CREATE TABLE IF NOT EXISTS images(
    filename TEXT,
    path TEXT,
    hash TEXT,
    exif TEXT
);
""")
import tiny_sqlite
db.exec("INSERT INTO images VALUES(?, ?, ?, ?)", filename, path, hash, exif)

for row in db.iterate("SELECT * FROM images"):
    let (filename, path, hash, exif) = row.unpack((string, string, string, string))
    echo filename, " ", path, " ", hash, " ", exif
]#
