//metadoc Installer category API
/*metadoc Installer description 
This proto is used to install packages.*/

Installer := Object clone do (

    /*doc Installer package
    The `Package` for which the `Installer` will install dependencies.*/
    package ::= nil

    /*doc Installer destination
    The directory into which the package should be installed.*/
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

    /*doc Installer install
    Installs `Installer package`.*/
    install := method(
        self _checkPackageSet
        self _checkDestinationSet
        # self package checkHasDep(dependency name)

        pkgDestination := self destination
        if (pkgDestination exists, 
            Exception raise(DirectoryExistsError with(
                self package name, pkgDestination path)))

        Logger log("📥 [[cyan bold;Installing [[reset;#{self package name}", 
            "output")

        self package runHook("beforeInstall")

        self _checkGitBranch

        self _build

        pkgDestination createIfAbsent

        self package dir copyTo(pkgDestination)

        self _installBinaries

        # self package appendPackage(Package with(pkgDestination path))

        self package runHook("afterInstall"))

    _checkPackageSet := method(
        if (self package isNil, Exception raise(PackageNotSetError with(""))))

    _checkDestinationSet := method(
        if (self destination isNil,
            Exception raise(DestinationNotSetError with(""))))

    _checkGitBranch := method(
        if (self package branch isNil, return)
        Eerie sh("git checkout #{self package branch}",
            false,
            self package dir path))

    _build := method(
        builder := Builder with(self package)
        builder build)

    # creates symlinks (UNIX-like) or .cmd files (Windows).  
    # This method is called only after the dependency is copied to the
    # destination folder. It works in the dependency's destination folder.
    _installBinaries := method(
        if (self package hasBinaries not, return)

        self _checkBinDestSet

        # this is the binaries directory (from where the binaries will be
        # installed), but at the destination
        # Note, here we consider that the dependency is already installed to
        # it's destination, so we can't use `dependency binDir` as the path has
        # changed
        binDir := self destination directoryNamed(self package binDir name)
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
        Eerie sh("chmod u+x #{bin path}")
        # create the link
        link := self binDestination fileNamed(bin name)
        link exists ifFalse(Eerie sh("ln -s #{bin path} #{link path}"))
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

)
