import pyexiv2  # type: ignore[import]
import shelf  # type: ignore[import]
from rich.progress import Progress, SpinnerColumn, TimeElapsedColumn

# These are the working directories and the filter used to skip useless files
workingDir = "working/"
duplicateDir = "dupes/"
skippedFileTypes = [".db", ".json", ".info"]  # These files are skipped

printMore = False

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

# Actual moving starts here
with progress:
    process = progress.add_task("[green]Processing...", total=len(files), start=True)
    for file in files:
        # Tries to get exif from pyexiv2, if it fails, it will use the modification date of the file instead
        try:
            with pyexiv2.Image(file) as img:
                data = img.read_exif(encoding="unicode-escape")
            if "Exif.Photo.DateTimeOriginal" in data:
                date = data["Exif.Photo.DateTimeOriginal"].split(" ")[0].split(":")
        except RuntimeError as e:
            if printMore:
                print(f"Exception occured:\n{e.args}")
            data = {}

        if data != {} and "Exif.Photo.DateTimeOriginal" in data:
            date = data["Exif.Photo.DateTimeOriginal"].split(" ")[0].split(":")
        else:
            if printMore:
                print(
                    f"Couldn't get exif data for file {file}, using last modified date instead."
                )
            date = shelf.getModDate(file).split(":")

        progress.update(process, advance=0.5)

        # folder0 is the first folder, by default it's date[0] (year)
        # folder1 is the second folder, by default it's date[1] (month)
        # folder2 is well the third folder, by default it's date[2] (day)
        # so the default folder structure is yyyy/mm/dd
        shelf.moveFile(file, date[0], date[1], date[2], duplicateDir, printMore)
        progress.update(process, advance=0.5)
