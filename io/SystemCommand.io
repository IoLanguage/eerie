SystemCommand := Object clone do(
    getPlatformName := method(
        return System platform asLowercase
    )

    lnFile := method(sourcePath, linkPath,
      if((self getPlatformName == "windows") or (self getPlatformName == "mingw"),
          Eerie sh("mklink /H #{linkPath asOSPath} #{sourcePath asOSPath}" interpolate)
          ,
          self lnDirectory(sourcePath, linkPath)
      )
    )

    lnDirectory := method(sourcePath, linkPath,
      if((self getPlatformName == "windows") or (self getPlatformName == "mingw"),
          Eerie sh("mklink /J #{linkPath asOSPath} #{sourcePath asOSPath}" interpolate)
          ,
          Eerie sh("ln -s #{sourcePath} #{linkPath}" interpolate)
      )
    )

    cpR := method(sourcePath, destinationPath,
        if((self getPlatformName == "windows") or (self getPlatformName == "mingw"),
            Eerie sh("xcopy #{sourcePath asOSPath} #{destinationPath asOSPath} /h /e" interpolate)
            ,
            Eerie sh("cp -r #{sourcePath asOSPath}/* #{destinationPath asOSPath}" interpolate)
        )
    )

    rmFilesContaining := method(string,
        Directory files foreach(item,
            item name containsSeq(string) ifTrue(item remove)
        )
    )

    rmFile := method(string,
        if((self getPlatformName == "windows") or (self getPlatformName == "mingw"),
            Eerie sh("del /F #{string}" interpolate)
            ,
            Eerie sh("rm -f #{string}" interpolate)
        )
    )

)
