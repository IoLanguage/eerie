Sequence do(
    toWinPath := method(path,
        winPath := path asMutable
        if(winPath == ".", winPath = winPath .. "\\")
        winPath asMutable replaceSeq("/", "\\")
    )
)

SystemCommand := Object clone do(
    ln := method(sourcePath, linkPath,
      if(System platform asLowercase == "windows",
          Eerie sh("mklink /D " .. ((linkPath .. " " .. sourcePath) toWinPath))
          ,
          Eerie sh("ln -s " .. (sourcePath .. " " .. linkPath))
      )
    )

    cpR := method(sourcePath, destinationPath,
        # FIXME: sometimes doesn't work without admin privileges
        curDir := Directory currentWorkingDirectory
        Directory setCurrentWorkingDirectory(sourcePath stringByExpandingTilde)

        Directory walk(item,
            item name at(0) != "."
            newPath := destinationPath stringByExpandingTilde asMutable appendPathSeq(item path asMutable afterSeq("."))
            (item type == "File") ifTrue(
                Directory with(newPath asMutable beforeSeq(item name)) createIfAbsent
                item copyToPath(newPath)
            )

            Directory with(newPath) create
        )

        Directory setCurrentWorkingDirectory(curDir)
    )

)

