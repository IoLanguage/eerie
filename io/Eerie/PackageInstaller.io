//metadoc PackageInstaller category API
//metadoc PackageInstaller description

PackageInstaller := Object clone do(
    compileFlags := if(System platform split first asLowercase == "windows",
        "-MD -Zi -DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE",
        "-Os -g -Wall -pipe -fno-strict-aliasing -DSANE_POPEN -DIOBINDINGS")

    //doc PackageInstaller path Path to at which package is located.
    path ::= nil

    //doc PackageInstaller root Directory with PackageInstallers' path.
    root := method(self root = Directory with(self path))

    //doc PackageInstaller config Contains contents of a eerie.json
    config ::= nil

    init := method(self config = Map clone)

    //doc PackageInstaller with(path)
    with := method(_path, self clone setPath(_path))

    /*doc PackageInstaller detect(path) Returns first PackageInstaller which 
    can install package at provided path.*/
    detect := method(_path,
        self instances foreachSlot(slotName, installer,
            installer canInstall(_path) ifTrue(
                return(installer with(_path))))

        Exception raise(
            "Don't know how to install package at #{_path}" interpolate))

    //doc PackageInstaller canInstall(path)
    canInstall := method(path, false)

    //doc PackageInstaller install
    install := method(
        Eerie addonsDir createIfAbsent
        false)

    /*doc PackageInstaller fileNamed(name) Returns a File relative to root
    directory.*/
    fileNamed := method(name, self root fileNamed(name))

    /*doc PackageInstaller dirNamed(name) Returns a Directory relative to root
    directory.*/
    dirNamed := method(name, self root directoryNamed(name))

    /*doc PackageInstaller loadConfig Looks for configuration data (in
    <code>protos</code> and <code>deps</code>) and then loads eerie.json.*/
    loadConfig := method(
        if(self fileNamed("protos") exists,
            self buildPackageJson,
            self extractDataFromPackageJson)

        configFile := self fileNamed("eerie.json")
        configFile exists ifTrue(
            self setConfig(configFile openForReading contents parseJson)
            configFile close))

    /*doc PackageInstaller extractDataFromPackageJson
    Creates <code>protos</code>, <code>deps</code> and <code>build.io</code>
    files from <code>eerie.json</code>*/
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

        pJson := self fileNamed("eerie.json")
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

//doc PackageInstaller instances
PackageInstaller instances := Object clone do(
    //doc PackageInstaller File Installs single files.
    doRelativeFile("PackageInstaller/File.io")
    //doc PackageInstaller Directory Installs whole directories.
    doRelativeFile("PackageInstaller/Directory.io")
    /*doc PackageInstaller IoAddon Installs directories structured as an Io
    addon.*/
    doRelativeFile("PackageInstaller/IoAddon.io")
)
