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

        # TODO copy content of `Package dir` to `self destination`

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

    /*doc PackageInstaller fileNamed(name) Returns a File relative to root
    directory.*/
    fileNamed := method(name, self root fileNamed(name))

    /*doc PackageInstaller dirNamed(name) Returns a Directory relative to root
    directory.*/
    dirNamed := method(name, self root directoryNamed(name))

    /*doc PackageInstaller loadConfig Looks for configuration data (in
    <code>protos</code> and <code>deps</code>) and then loads the manifest.*/
    loadConfig := method(
        if(self fileNamed("protos") exists,
            self buildPackageJson,
            self extractDataFromPackageJson)

        configFile := self fileNamed(Eerie manifestName)
        configFile exists ifTrue(
            self setConfig(configFile openForReading contents parseJson)
            configFile close))

    /*doc PackageInstaller extractDataFromPackageJson
    Creates <code>protos</code>, <code>deps</code> and <code>build.io</code>
    files from the manifest.*/
    extractDataFromPackageJson := method(
        providedProtos  := self config at("protos") ?join(" ")
        providedProtos isNil ifTrue(
            providedProtos = "")

        deps := self config at("dependencies")
        protoDeps := deps ?at("protos") ?join(" ")
        if(protoDeps isNil, protoDeps = "")

        self fileNamed("protos")  create openForUpdating write(
            providedProtos) close
        self fileNamed("depends") create openForUpdating write(
            protoDeps) close

        self fileNamed("build.io") exists ifFalse(
            headerDeps := deps ?at("headers")
            libDeps := deps ?at("libs")

            buildIo := list("AddonBuilder clone do(")
                libDeps ?foreach(lib,
                    buildIo append("""  dependsOnLib("#{lib}")"""))
                headerDeps ?foreach(header,
                    buildIo append("""  dependsOnHeader("#{header}")"""))
                buildIo append(")\n")

            self fileNamed("build.io") remove create openForUpdating write(
                buildIo join("\n") interpolate) close))

    //doc PackageInstaller buildPackageJson
    buildPackageJson := method(
        package := Map with(
            "dependencies", list(),
            "protos",       list())

        providedProtos := self fileNamed("protos")
        protoDeps := self fileNamed("depends")

        providedProtos exists ifTrue(
            providedProtos openForReading contents split(" ") foreach(pp,
                package at("protos") append(pp strip)))
        providedProtos close

        protoDeps exists ifTrue(
            protoDeps openForReading contents split(" ") foreach(pd, 
                package at("dependencies") append(pd strip)))
        protoDeps close

        pJson := self fileNamed(Eerie manifestName)
        pJson exists ifFalse(pJson create openForUpdating write(package asJson))
        pJson close

        self)
)

# Errors
PackageInstaller do (
    DirectoryExistsError := Eerie Error clone setErrorMsg("Can't install " ..
        "the package #{call evalArgAt(0)}. The destination directory " ..
        "'#{call evalArgAt}' already exists.")

    BuildioMissingError := Eerie Error clone setErrorMsg("Don't know how to " ..
        "compile #{call evalArgAt(0)}. The 'build.io' file is missing.")
)
