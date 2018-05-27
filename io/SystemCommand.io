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
            (item type == "Directory") and(item isAccessible not) ifTrue(continue)
            newPath := destinationPath stringByExpandingTilde asMutable appendPathSeq(item path asMutable afterSeq("."))
            (item type == "File") ifTrue(
                e := try(
                    Directory with(newPath asMutable beforeSeq(item name)) createIfAbsent
                    item copyToPath(newPath)
                )

                e catch(Exception,
                    e coroutine backTraceString containsSeq("Permission denied") ifTrue(continue)
                )
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

