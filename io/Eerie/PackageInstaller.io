//metadoc PackageInstaller category API
//metadoc PackageInstaller description This object is used to install packages.

PackageInstaller := Object clone do (
    compileFlags := if(System platform split first asLowercase == "windows",
        "-MD -Zi -DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE",
        "-Os -g -Wall -pipe -fno-strict-aliasing -DSANE_POPEN -DIOBINDINGS")

    /*doc PackageInstaller package Returns `Package`, which this installer
    installs.*/
    package := nil

    /*doc PackageInstaller destination Directory where `Package` will be
    installed.*/
    destination := method(
        Eerie addonsDir .. "/#{self package name}" interpolate)

    //doc PackageInstaller with(package) Init `PackageInstaller` with `Package`.
    with := method(pkg, self clone package = pkg)

    //doc PackageInstaller install Installs the `PackageInstaller package`.
    install := method(
        if (self destination exists, 
            Exception raise(DirectoryExistsError with(
                self package name, self destination path)))

        self destination create

        self compile

        Directory cp(self package dir, self destination)

        if(Eerie isGlobal, self installBinaries)

        true)

    //doc PackageInstaller compile Compiles the package if it has native code.
    compile := method(
        sourceDir := self package dir createSubdirectory("source")
        if(sourceDir items isEmpty, 
            Eerie log(
                "There is nothing to compile. The 'source' directory " ..
                "('#{sourceDir path}') is empty.")
            return self)

        buildio := File with(self package dir path .. "/build.io")
        if (buildio exists not, 
            Exception raise(BuildioMissingError with(self package name)))

        builderContext := Object clone
        builderContext doRelativeFile("AddonBuilder.io")

        self package dir createSubdirectory("_build")

        addon := builderContext doFile(self package dir path .. "/build.io")
        addon folder := self package dir
        addon build(self compileFlags)

        self)

    /*doc PackageInstaller installBinaries For global packages, creates symlinks 
    (UNIX-like) or .cmd files (Windows) for files of the package's `bin`
    directory in `Eerie globalBinDir`.*/
    installBinaries := method(
        binDir := self destination createSubdirectory("bin")
        if (binDir files isEmpty, return)

        isWindows := System platform containsAnyCaseSeq("windows") or(
            System platform containsAnyCaseSeq("mingw"))

        binDir files foreach(f, if(isWindows, 
            self _createCmdForBin(f),
            self _createLinkForBin(f))))

    # This method is used on Windows to create .cmd file to be able to execute a
    # package binary as a normal command (i.e. `eerie` instead of
    # `io /path/to/eerie/bin`)
    _createCmdForBin := method(bin,
        cmd := Eerie globalBinDir fileNamed(bin name .. ".cmd")
        cmd open setContents("io #{bin path} %*" interpolate) close)

    # We just create a link for binary on unix-like system
    _createLinkForBin := method(bin,
        # make sure it's executable
        Eerie sh(
            "chmod u+x #{self destination path}/bin/#{bin name}" interpolate)
        # create the link
        link := Eerie globalBinDir fileNamed(bin name)
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
)
