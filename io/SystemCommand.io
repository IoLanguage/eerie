SystemCommand := Object clone do(
    getPlatformName := method(return System platform asLowercase)

    _isWindows := method(
        (self getPlatformName == "windows") or(self getPlatformName == "mingw"))

    # make symbolic link for a file
    lnFile := method(sourcePath, linkPath,
        if(self _isWindows) \
        then(
            Eerie sh("mklink /H #{linkPath asOSPath} #{sourcePath asOSPath}" \
                interpolate)
        ) else (
            self lnDirectory(sourcePath, linkPath)))
            

    # make symbolic link for a directory
    lnDirectory := method(sourcePath, linkPath,
        if(self _isWindows) \
        then(
            Eerie sh("mklink /J #{linkPath asOSPath} #{sourcePath asOSPath}" \
                interpolate)
        ) else (
            Eerie sh("ln -s #{sourcePath} #{linkPath}" interpolate)))

    # copy recursively
    cpR := method(sourcePath, destinationPath,
        if(self _isWindows) \
        then(
            sourceOs := sourcePath asOSPath
            destinationOs := destinationPath asOSPath
            Eerie sh(
                "xcopy #{sourceOs} #{destinationOs} /h /e" interpolate)
        ) else (
            Eerie sh(
                "cp -r #{sourcePath asOSPath}/* #{destinationPath asOSPath}" \
                interpolate)))

    # remove all files which contain the string
    rmFilesContaining := method(string,
        Directory files foreach(item,
            item name containsSeq(string) ifTrue(item remove)))

    # remove a file
    rmFile := method(string,
        if(self _isWindows) \
        then(
            Eerie sh("del /F #{string}" interpolate)
        ) else (
            Eerie sh("rm -f #{string}" interpolate)))

)
