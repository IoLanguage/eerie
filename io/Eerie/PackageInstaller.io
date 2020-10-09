//metadoc PackageInstaller category API
/*metadoc PackageInstaller description This object is used to install packages.
You should `setDestination` right after initialization, otherwise it will raise
an exception when you'll try to install a package. You should also
`setDestBinName` if you install a `Package` with binaries.*/

PackageInstaller := Object clone do (
    compileFlags := if(System platform split first asLowercase == "windows",
        "-MD -Zi -DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE",
        "-Os -g -Wall -pipe -fno-strict-aliasing -DSANE_POPEN -DIOBINDINGS")

    /*doc PackageInstaller destination The root `Directory` where `Package` will
    be installed.*/
    destination ::= nil

    /* PackageInstaller destBinName The name of the directory, where binaries
    (if any) will be installed.*/
    destBinName ::= nil

    /*doc PackageInstaller install(package, installBin)
    Installs the given `Package` into `PackageInstaller destination`/`package
    name`. If the second argument is `true`, the binaries from the package's
    `bin` directory will also be installed. 

    Returns `true` if the package installed successfully.*/
    install := method(pkg, includeBin,
        self _checkDestination

        pkgDestination := self _packageDestination(pkg)
        if (pkgDestination exists, 
            Exception raise(DirectoryExistsError with(
                pkg name, pkgDestination path)))

        pkgDestination create

        self compile(pkg)

        Directory cp(pkg dir, pkgDestination)

        if(includeBin, self _installBinaries(pkg))

        true)

    _checkDestination := method(
        if (self destination isNil, 
            Exception raise(DestinationNotSetError clone)))

    # this is the directory inside `destination` which represents the package
    # and contains its sources
    _packageDestination := method(pkg, 
        self destination directoryNamed(pkg name))

    _checkDestBinName := method(
        if (self destBinName isNil or self destBinName isEmpty,
            Exception raise(DestinationBinNameNotSetError clone)))

    # binaries will be installed in this directory
    _binDestination := method(pkg,
        self destination directoryNamed(pkg name) directoryNamed(
            self binDestName))

    /*doc PackageInstaller compile(package) Compiles the `Package` if it has
    native code. Returns `self`.*/
    compile := method(pkg,
        sourceDir := pkg dir createSubdirectory("source")
        if(sourceDir items isEmpty, 
            Eerie log(
                "There is nothing to compile. The 'source' directory " ..
                "('#{sourceDir path}') is empty.")
            return self)

        buildio := File with(pkg dir path .. "/build.io")
        if (buildio exists not, 
            Exception raise(BuildioMissingError with(pkg name)))

        builderContext := Object clone
        builderContext doRelativeFile("AddonBuilder.io")

        pkg dir createSubdirectory("_build")

        addon := builderContext doFile(pkg dir path .. "/build.io")
        addon folder := pkg dir
        addon build(self compileFlags)

        self)

    # For global packages, creates symlinks (UNIX-like) or .cmd files (Windows)
    # for files of the package's `bin` directory in destination's `destBinName`
    # directory.
    _installBinaries := method(pkg,
        self _checkDestBinName
        pkgDestination := self _packageDestination(pkg)
        binDir := pkgDestination createSubdirectory("bin")
        if (binDir files isEmpty, return)

        isWindows := System platform containsAnyCaseSeq("windows") or(
            System platform containsAnyCaseSeq("mingw"))

        binDest := self _binDestination(pkg)
        binDir files foreach(f, if(isWindows, 
            self _createCmdForBin(f, binDest),
            self _createLinkForBin(f, binDest))))

    # This method is used on Windows to create .cmd file to be able to execute a
    # package binary as a normal command (i.e. `eerie` instead of
    # `io /path/to/eerie/bin`)
    _createCmdForBin := method(bin, binDest,
        cmd := binDest fileNamed(bin name .. ".cmd")
        cmd open setContents("io #{bin path} %*" interpolate) close)

    # We just create a link for binary on unix-like system
    _createLinkForBin := method(bin, binDest,
        # make sure it's executable
        Eerie sh("chmod u+x #{bin path}" interpolate)
        # create the link
        link := binDest fileNamed(bin name)
        link exists ifFalse(SystemCommand lnFile(bin path, link path))
        link close)
)

# Errors
PackageInstaller do (
    DirectoryExistsError := Eerie Error clone setErrorMsg("Can't install " ..
        "the package #{call evalArgAt(0)}. The destination directory " ..
        "'#{call evalArgAt}' already exists.")

    BuildioMissingError := Eerie Error clone setErrorMsg("Don't know how to " ..
        "compile #{call evalArgAt(0)}. The 'build.io' file is missing.")

    DestinationNotSetError := Eerie Error clone setErrorMsg(
        "Package installer destination directory didn't set.")

    DestinationBinNameNotSetError := Eerie Error clone setErrorMsg(
        "Name of the destination directory where binaries will be installed " ..
        "didn't set.")
)
