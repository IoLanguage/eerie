//metadoc Installer category API
/*metadoc Installer description 
This proto is used to install packages and their updates.*/

Installer := Object clone do (

    /*doc Installer package
    The `Package` for which the `Installer` will install dependencies.

    For updates this is a newer version of the package.*/
    package ::= nil

    /*doc Installer destination
    The directory into which the package should be installed.

    For updates this is the directory of the `Package` for which the update will
    be installed.*/
    //doc Installer setDestination(Directory)
    destination ::= nil

    /*doc Installer binDestination
    The directory into which the package binaries should be installed.*/
    binDestination ::= nil

    /*doc Installer with(package, destination, binDestination)
    Initializes installer with the given package, destination directory path
    (`Sequence`) and binaries destination directory path (`Sequence`).

    If the package doesn't have binaries `binDestination` is optional.*/ 
    with := method(pkg, dest, binDest,
        klone := self clone \
            setPackage(pkg) \
                setDestination(Directory with(dest))
        if (binDest isNil, return klone)
        klone setBinDestination(Directory with(binDest))
        klone)

    /*doc Installer update(version) 
    Install `package` as an update of `destination`.

    If version (`SemVer`) is `nil`, installs the recent version.*/
    update := method(version,
        self _checkPackageSet
        self _checkDestinationSet

        destPackage := Package with(self destination path)
        self _checkSame(destPackage)

        ver := self versionFor(version)

        if (ver == destPackage manifest version,
            Logger log(
                "☑  #{destPackage manifest name} " .. 
                "v#{destPackage manifest version asSeq} " ..
                "is already updated", 
                "output")
            return)

        self _logUpdate(ver, destPackage)

        destPackage runHook("beforeUpdate")
        destPackage remove
        self install(ver)
        destPackage runHook("afterUpdate")

        Logger log(
            "☑  [[magenta bold;#{destPackage manifest name}[[reset; is " ..
            "[[magenta bold;#{ver originalSeq}[[reset; now",
            "output"))

    _checkPackageSet := method(
        if (self package isNil, Exception raise(PackageNotSetError with(""))))

    _checkDestinationSet := method(
        if (self destination isNil,
            Exception raise(DestinationNotSetError with(""))))

    _checkSame := method(destPackage,
        if (self package manifest name != destPackage manifest name, 
            Exception raise(
                DifferentPackageError with(
                    destPackage manifest name, self package manifest name))))

    /*doc Installer versionFor(SemVer) 
    Get version (`SemVer`) of the `package`, which will be used for passed
    `SemVer`*/
    versionFor := method(version,
        if (version isNil,
            return SemVer highestIn(self package versions),
            return version highestIn(self package versions)))

    _logUpdate := method(version, destPackage,
        if (version > destPackage manifest version) then (
            Logger log("⬆ [[cyan bold;Updating [[reset;" ..
                "#{destPackage manifest name} " ..
                "from [[magenta bold;" ..
                "v#{destPackage manifest version asSeq}[[reset; " ..
                "to [[magenta bold;v#{version asSeq}", "output")
        ) elseif (version < destPackage manifest version) then (
            Logger log(
                "⬇ [[cyan bold;Downgrading [[reset;" .. 
                "#{destPackage manifest name} " ..
                "from v#{destPackage manifest version asSeq} " ..
                "to v#{version asSeq}", "output")))

    /*doc Installer install(version)
    Installs `Installer package`.

    If version (`SemVer`) is `nil`, installs the recent version.*/
    install := method(version,
        self _checkPackageSet
        self _checkDestinationSet

        if (self destination exists, 
            Exception raise(DirectoryExistsError with(
                self package manifest name, self destination path)))

        Logger log("📥 [[cyan bold;Installing [[reset;#{self package manifest name}", 
            "output")

        self package runHook("beforeInstall")

        self _checkGitBranch

        ver := self versionFor(version)

        if (ver isNil not, self _checkGitTag(ver))

        self _build

        self destination createIfAbsent

        self package struct root copyTo(self destination)

        self _installBinaries

        self package runHook("afterInstall"))

    _checkGitBranch := method(
        if (self package manifest branch isNil, return)
        System sh("git checkout #{self package manifest branch}",
            false,
            self package struct root path))

    _checkGitTag := method(version,
        System sh("git checkout tags/#{version originalSeq}", 
            false,
            self package struct root path))

    _build := method(
        builder := Builder with(self package)
        builder build)

    # creates symlinks (UNIX-like) or .cmd files (Windows).  
    # This method is called only after the dependency is copied to the
    # destination folder. It works in the dependency's destination folder.
    _installBinaries := method(
        if (self package struct hasBinaries not, return)

        self _checkBinDestSet

        # this is the binaries directory (from where the binaries will be
        # installed), but at the destination
        # Note, here we consider that the dependency is already installed to
        # it's destination, so we can't use `dependency struct bin` as the path has
        # changed
        binDir := self destination directoryNamed(self package struct bin name)
        binDir files foreach(f, 
            if (Eerie isWindows, 
                self _createCmdForBin(f),
                self _createLinkForBin(f))))

    _checkBinDestSet := method(
        if (self binDestination isNil, 
            Exception raise(BinDestNotSetError with(""))))

    # This method is used on Windows to create .cmd file to be able to execute a
    # package binary as a normal command (i.e. `eerie` instead of
    # `io /path/to/eerie/bin`)
    _createCmdForBin := method(bin,
        cmdFile := self binDestination fileNamed(bin name .. ".cmd")
        cmdFile open setContents("io #{bin path} %*" interpolate) close)

    # We just create a link for binary on unix-like system
    _createLinkForBin := method(bin,
        # make sure it's executable
        System sh("chmod u+x #{bin path}")
        # create the link
        link := self binDestination fileNamed(bin name)
        link exists ifFalse(System sh("ln -s #{bin path} #{link path}"))
        link close)

)

# Errors
Installer do (

    //doc Installer PackageNotSetError
    PackageNotSetError := Eerie Error clone setErrorMsg("Package isn't set.")

    //doc Installer DirectoryExistsError
    DirectoryExistsError := Eerie Error clone setErrorMsg("Can't install " ..
        "the package #{call evalArgAt(0)}. The destination directory " ..
        "'#{call evalArgAt(1)}' already exists.")

    //doc Installer DestinationNotSetError
    DestinationNotSetError := Eerie Error clone setErrorMsg(
        "Destination directory isn't set.")

    //doc Installer BinDestNotSetError
    BinDestNotSetError := Eerie Error clone setErrorMsg(
        "Binary destination isn't set")

    //doc Installer DifferentPackageError
    DifferentPackageError := Eerie Error clone setErrorMsg(
        "Can't update package '#{call evalArgAt(0)}' " .. 
        "with package '#{call evalArgAt(1)}'")

)
