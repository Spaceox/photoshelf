import pyexiv2  # type: ignore[import]
import shelf  # type: ignore[import]
from io import IOBase
from rich.progress import Progress, SpinnerColumn, TimeElapsedColumn
from gc import collect
import threading

# These are the working directories and the filter used to skip useless files
workingDir = "working/"
duplicateDir = "dupes/"
skippedFileTypes = [".db", ".json", ".info"]  # These files are skipped

shelf.setEchoMore(True)


def getDate(image: IOBase) -> list[str]:
    try:
        with pyexiv2.Image(image) as img:
            exif = img.read_exif(encoding="unicode-escape")
            if (
                "Exif.Photo.DateTimeOriginal" in exif
                and exif["Exif.Photo.DateTimeOriginal"] != ""
            ):
                return list(
                    exif["Exif.Photo.DateTimeOriginal"].split(" ")[0].split(":")
                )
            else:
                shelf.niceishLogText(
                    f"Date doesn't exist in {image}, using last modified date instead."
                )
                return list(shelf.getModDate(image).split(":"))
    except RuntimeError as e:
        shelf.niceishLogText(
            f"""
                             Exception occured:
                             {e.args}
                             Couldn't get exif data for {image}, using last modified date instead.
                             """
        )
        return list(shelf.getModDate(image).split(":"))


shelf.niceishLogText("Loading...")
# Pyexiv2 settings
pyexiv2.set_log_level(
    4
)  # If set to anything else, it will throw an exception loading some photos with weird exif data
pyexiv2.enableBMFF()  # Apparently it's fine to leave this on

# Adds a spinner and time elapsed to the rich progressbar
progress = Progress(
    SpinnerColumn(),
    *Progress.get_default_columns(),
    TimeElapsedColumn(),
)

# Loads list of files from the nim extension, I think it's faster than using python's os module, but I may be using is badly as it's compiled in c and thus should be the same as nim
files = shelf.getFiles(workingDir, duplicateDir)

# Files that don't pass the "skippedFileTypes" filter
listOfRejects = [
    file
    for file in files
    for ftype in skippedFileTypes
    if file.casefold().endswith(ftype)
]

# Removes items in listOfRejects from files
for reject in listOfRejects:
    files.remove(reject)

del listOfRejects  # It's not needed after this and can free up some memory depending on how many files are "rejected"
collect()

# Actual moving starts here
with progress:
    process = progress.add_task("[green]Processing...", total=len(files), start=True)
    for file in files:
        # Tries to get exif from pyexiv2, if it fails, it will use the modification date of the file instead
        date = getDate(file)
        progress.update(process, advance=0.5)

        # folder0 is the first folder, by default it's date[0] (year)
        # folder1 is the second folder, by default it's date[1] (month)
        # folder2 is well the third folder, by default it's date[2] (day)
        # so the default folder structure is yyyy/mm/dd

        t = threading.Thread(
            target=shelf.moveFile(file, date[0], date[1], date[2], duplicateDir)
        )
        shelf.niceishLogText(
            "Moving file, if's a big file it might get stuck for a bit"
        )
        t.start()
        progress.update(process, advance=0.5)
