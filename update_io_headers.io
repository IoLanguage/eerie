#!/usr/bin/env io

# this script downloads and updates headers inside `ioheaders` directory

Importer addSearchPath("io")

srcName := "iolang"

System system(
    "git clone https://github.com/IoLanguage/io.git #{srcName}" interpolate)

Directory with("ioheaders") create remove create

Directory with("#{srcName}/libs/iovm/source" interpolate) \
    filesWithExtension(".h") \
        foreach(f, f moveTo("ioheaders/#{f name}" interpolate))

Directory with(srcName) remove
