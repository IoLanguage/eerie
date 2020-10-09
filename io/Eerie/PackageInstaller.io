//metadoc PackageInstaller category API
//metadoc PackageInstaller description This object is used to install packages.

PackageInstaller := Object clone do (
    compileFlags := if(System platform split first asLowercase == "windows",
        "-MD -Zi -DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE",
        "-Os -g -Wall -pipe -fno-strict-aliasing -DSANE_POPEN -DIOBINDINGS")

    /*doc PackageInstaller package Returns `Package`, which this installer
    installs.*/
    package := nil

    //doc PackageInstaller with(package) Init `PackageInstaller` with `Package`.
    with := method(pkg, self clone package = pkg)

    /*doc PackageInstaller destination Directory where `Package` will be
    installed.*/
    destination := method(
        Eerie addonsDir .. "/#{self package name}" interpolate)

    //doc PackageInstaller install Installs the `PackageInstaller package`.
    install := method(
        self destination createIfAbsent
        # TODO check existence and raise an exception if it's installed

        # TODO copy content of `Package dir` to `self destination`

        sourceDir := self dirNamed("source") createIfAbsent
        if(sourceDir files isEmpty not, self compile)

        binDir := self dirNamed("bin") createIfAbsent
        if(Eerie isGlobal and binDir files isEmpty not, self installBinaries)

        true)

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

    //doc PackageInstaller compile Compiles the package.
    compile := method(
        builderContext := Object clone
        builderContext doRelativeFile("AddonBuilder.io")
        prevPath := Directory currentWorkingDirectory
        Directory setCurrentWorkingDirectory(self path)

        Directory with(self path .. "/_build") createIfAbsent

        addon := builderContext doFile((self path) .. "/build.io")
        addon folder := Directory with(self path)
        addon build(self compileFlags)

        Directory setCurrentWorkingDirectory(prevPath)
        self)

    /*doc PackageInstaller installBinaries For global packages, creates symlinks 
    (UNIX-like) or .cmd files (Windows) for files of the package's `bin`
    directory in `$EERIEDIR/bin`.*/
    installBinaries := method(
        isWindows := System platform containsAnyCaseSeq("windows") or(
            System platform containsAnyCaseSeq("mingw"))

        self dirNamed("bin") files foreach(f, if(isWindows, 
            self _createCmdForBin(f),
            self _createLinkForBin(f))))

    # This method is used on Windows to create .cmd file to be able to execute a
    # package binary as a normal command (i.e. `eerie` instead of
    # `io /path/to/eerie/bin`)
    _createCmdForBin := method(bin,
        cmd := File with(Eerie globalEerieDir .. "/bin/" .. bin name .. ".cmd")
        cmd open setContents("io #{bin path} %*" interpolate) close)

    # We just create a link for binary on unix-like system
    _createLinkForBin := method(bin,
        # make sure it's executable
        Eerie sh("chmod u+x #{self path}/bin/#{bin name}" interpolate)
        # create the link
        link := File with(Eerie globalEerieDir .. "/bin/" .. bin name)
        link exists ifFalse(SystemCommand lnFile(bin path, link path))
        link close)
)
