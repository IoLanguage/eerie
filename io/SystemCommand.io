SystemCommand := Object clone do(
    ln := method(sourcePath, linkPath,
      if(System platform asLowercase == "windows",
          Eerie sh("mklink /D " .. ((linkPath .. " " .. sourcePath) asOSPath))
          ,
          Eerie sh("ln -s " .. (sourcePath .. " " .. linkPath))
      )
    )

    cpR := method(sourcePath, destinationPath,
        curDir := Directory currentWorkingDirectory
        Directory setCurrentWorkingDirectory(sourcePath stringByExpandingTilde)

        Directory walk(item,
            (item isDirectory) and(item isAccessible not) ifTrue(continue)
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

    rmFilesContain := method(string,
        Directory files foreach(item,
            item name containsSeq(string) ifTrue(item remove)
        )
    )
)

