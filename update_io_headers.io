#!/usr/bin/env io

# this script downloads and updates headers inside `ioheaders` directory

Importer addSearchPath("io")

srcName := "iolang"

System system(
    "git clone https://github.com/IoLanguage/io.git #{srcName}" interpolate)

Directory with("ioheaders") create remove create

copyHeadersFrom := method(path,
    Directory with(path) filesWithExtension(".h") \
        foreach(f, f moveTo("ioheaders/#{f name}" interpolate)))

# basekit
copyHeadersFrom("#{srcName}/libs/basekit/source" interpolate)

# coroutine
copyHeadersFrom("#{srcName}/libs/coroutine/source" interpolate)

# garbage collector
copyHeadersFrom("#{srcName}/libs/garbagecollector/source" interpolate)

# iovm
copyHeadersFrom("#{srcName}/libs/iovm/source" interpolate)

Directory with(srcName) remove
