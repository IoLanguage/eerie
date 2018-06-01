SystemCommand := Object clone do(
    getPlatformName = method(
        return System platform asLowercase
    )

    ln := method(sourcePath, linkPath,
      if(getPlatformName == "windows" or getPlatformName == "mingw",
          Eerie sh("mklink /D " .. ((linkPath .. " " .. sourcePath) asOSPath))
          ,
          Eerie sh("ln -s " .. (sourcePath .. " " .. linkPath))
      )
    )

    cpR := method(sourcePath, destinationPath,
        if(getPlatformName == "windows" or getPlatformName == "mingw",
            Eerie sh("xcopy #{sourcePath asOSPath} #{destinationPath asOSPath} /h /e" interpolate)
            ,
            Eerie sh("cp -rf #{sourcePath asOSPath} #{destinationPath asOSPath}" interpolate)
        )
    )

    rmFilesContain := method(string,
        Directory files foreach(item,
            item name containsSeq(string) ifTrue(item remove)
        )
    )
)


