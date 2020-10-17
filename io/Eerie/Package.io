//metadoc Package category API
//metadoc Package description Represents an Eerie package.
doRelativeFile("SemVer.io")

Package := Object clone do (

    //doc Package config Package's config file (the manifest) as a `Map`.
    config ::= nil

    //doc Package dir Directory of this package.
    dir ::= nil

    /*doc Package sourceDir The `source` directory. `Directory` with native
    code.*/
    sourceDir := lazySlot(self dir createSubdirectory("source"))

    /*doc Package binDir 
    The `bin` directory. `Directory` with binaries of the package.*/
    binDir := lazySlot(self dir directoryNamed("bin"))

    /*doc Package installedBinDir
    Get the `_bin` directory, where binaries of dependencies are installed.*/
    installedBinDir := lazySlot(self dir createSubdirectory("_bin"))

    //doc Package addonsDir Get the `_addons` `Directory`.
    addonsDir := lazySlot(self dir createSubdirectory("_addons"))

    /*doc Package tmpDir 
    Get `_tmp` `Directory`, the temporary directory used by `Downloader` to
    download dependencies into.*/
    tmpDir := lazySlot(self dir createSubdirectory("_tmp"))

    /*doc Package buildDir 
    Get `_build` `Directory`, the directory where build artifacts are stored.*/
    buildDir := lazySlot(self dir createSubdirectory("_build"))

    /*doc Package headersBuildDir
    Get the output `Directory` where all the headers of this package will be
    installed.*/
    headersBuildDir := lazySlot(self buildDir createSubdirectory("headers"))

    /*doc Package objsBuildDir
    Get the output objects (`.o`) `Directory`.*/
    objsBuildDir := lazySlot(self buildDir createSubdirectory("objs"))

    /*doc Package dllBuildDir
    Get the output `Directory` for dynamic library this package represents.*/
    dllBuildDir := lazySlot(self buildDir createSubdirectory("dll"))

    /*doc Package staticLibBuildDir
    Get the output `Directory` for static library this package represents.*/
    staticLibBuildDir := lazySlot(self buildDir createSubdirectory("lib"))

    /*doc Package dllFileName 
    Get the file name of the dynamic library provided by this package in the
    result of compilation with `lib` prefix.*/
    dllFileName := method("lib" .. self dllName .. "." .. self _dllExt)

    /*doc Package dllName 
    Get the name of the dynamic library provided by this package in the result
    of compilation. Note, this is the name of the library, not the name of the
    dll file (i.e. without extension and `lib` prefix). Use `Package
    dllFileName` for the DLL file name.*/
    dllName := method("Io" .. self name)

    _dllExt := method(
        if (Eerie isWindows) then (
            return "dll"
        ) elseif (Eerie platform == "darwin") then (
            return "dylib"
        ) else (
            return "so"))

    /*doc Package staticLibFileName 
    Get the file name of the static library provided by this package in the
    result of compilation.*/
    staticLibFileName := method("lib" .. self staticLibName .. ".a")

    /*doc Package staticLibName 
    Get the name of the static library provided by this package in the result of
    compilation. Note, this is the name of the library, not the name of the dll
    file (i.e. the extension and without `lib` prefix). Use `Package
    staticLibFileName` for the static library file name.*/
    staticLibName := method("Io" .. self name)

    /*doc Package dllPath
    Get the path to the dynamic library this package represents.*/
    dllPath := method(self dllBuildDir path .. "/" .. self dllFileName)

    /*doc Package staticLibPath
    Get the path to the static library this package represents.*/
    staticLibPath := method(
        self staticLibBuildDir path .. "/" .. self staticLibFileName)

    //doc Package buildio The `build.io` file.
    buildio := lazySlot(self dir fileNamed("build.io"))

    /*doc Package installedPackages 
    Get the `List` of installed dependencies for this package.*/
    installedPackages := lazySlot(
        self addonsDir directories map(dir, Package with(dir)))

    /*doc Package packageNamed 
    Get the dependency package with the provided name (`Sequence`) if it's
    installed. Otherwise it returns `nil`.*/ 
    packageNamed := method(name,
        self installedPackages detect(pkg, pkg name == name))

    //doc Package version Returns parsed version (`SemVer`) of the package.
    version ::= nil
    
    //doc Package name
    name := method(self config at("name"))

    //doc Package setName(name)
    setName := method(v,
        self config atPut("name", v)
        self)

    /*doc Package uri Either local path or git url. Parsed from `path` field of
    the manifest.*/
    uri := method(
        dir := self config at("path") at("dir")
        if (dir isNil not, 
            dir,
            self config at("path") at("git") at("url")))

    //doc Package downloader Instance of [[Downloader]] for this package.
    downloader ::= nil

    /*doc Package with(dir) 
    Creates new package from provided `Directory`. Raises `NotPackageError` if
    the directory is not an Eerie package. Use this to initialize a `Package`.*/
    with := method(dir,
        _checkDirectoryPackage(dir)

        klone := self clone setDir(dir)
        manifest := File with(dir path .. "/#{Eerie manifestName}" interpolate) 
        klone setConfig(manifest contents parseJson)
        klone setVersion(SemVer fromSeq(klone config at("version")))
        # call to init the list
        klone installedPackages
        klone)

    _checkDirectoryPackage := method(dir,
        ioDir := dir directoryNamed("io")
        manifest := File with(dir path .. "/#{Eerie manifestName}" interpolate)
        if ((dir exists and manifest exists and ioDir exists) not,
            Exception raise(NotPackageError with(dir path)))

        self _validateManifest(manifest))

    _validateManifest := method(manifest,
        parsed := manifest contents parseJson

        # we don't check 'version' field `isEmpty` because it's checked better
        # by `SemVer`
        test := parsed at("name") isNil
        test = test or parsed at("name") isEmpty 
        self _checkField(test, "The 'name' field is required.", manifest path)

        test = parsed at("version") isNil
        self _checkField(test, "The 'version' field is required.", 
            manifest path)

        test = parsed at("author") isNil
        test = test or parsed at("author") isEmpty
        self _checkField(test, "The 'author' field is required.", manifest path)

        test = test or parsed at("path") isNil
        self _checkField(test, "The 'path' field is required.", manifest path)

        test = parsed at("path") at("dir") isNil or \
            parsed at("path") at("dir") isEmpty
        test = test and parsed at("path") at("git") isNil
        self _checkField(test,
            "Either 'path.dir' or 'path.git' is required.", manifest path)

        if (parsed at("path") at("git") isNil not,
            test = parsed at("path") at("git") at("url") isNil or \
                parsed at("path") at("git") at("url") isEmpty
            self _checkField(test,
                "'path.git.url' is required for 'path.git'.", manifest path))

        test = parsed at("protos") isNil
        self _checkField(test, "The 'protos' field is required.", manifest path)

        test = test or parsed at("protos") type != "List"
        self _checkField(test,
            "The 'protos' field should be an array.",
            manifest path)

        deps := parsed at("dependencies")
        self _checkField(deps type != "Map", 
            "The 'dependencies' field should be an object.", manifest path)

        if (deps ?at("packages") isNil not and \
            deps ?at("packages") isEmpty not,

            test = deps at("packages") type != "List"
            self _checkField(test,
                "The 'dependencies.packages' field should be an array.",
                manifest path)

            deps at("packages") ?foreach(p,
                test = p at("name") isNil
                test = test or p at("name") isEmpty
                self _checkField(test,
                    "The 'dependencies.packages[n].name' is required.",
                    manifest path)

                test = test or p at("version") isNil
                self _checkField(test,
                    "The 'dependencies.packages[n].version' is required.",
                    manifest path)

                test = test or p at("path") isNil
                test = test or p at("path") isEmpty
                self _checkField(test,
                    "The 'dependencies.packages[n].path' is required.",
                    manifest path))))

    # the first argument is a boolean. If it's `true`,
    # `InsufficientManifestException` will raise with the message at the second
    # argument.
    # The third argument is the manifest path.
    _checkField := method(test, msg, path,
        test ifTrue(Exception raise(InsufficientManifestError with(path, msg))))

    /*doc Package hasNativeCode 
    Returns `true` if the package has native code and `false` otherwise.*/
    hasNativeCode := method(
        self sourceDir files isEmpty not or(self sourceDir directories isEmpty
            not))

    /*doc Package hasBinaries
    Returns `true` if the `Package binDir` has files and `false` otherwise.*/
    hasBinaries := method(self binDir exists and self binDir files isEmpty not)

    //doc Package providesProtos Returns list of protos this package provides.
    providesProtos := method(
        p := self config at("protos")
        if(p isNil, list(), p))

    /*doc Package dependencies([category])
    Returns list of dependencies this package has. <code>category</code> can be 
    <code>protos</code>, <code>packages</code>, <code>headers</code> or 
    <code>libs</code>.*/
    dependencies := method(category,
        d := self config at("dependencies")
        if(category and d and d isEmpty not, d = d at(category))
        if(d isNil, list(), d))

    /*doc Package runHook(hookName) 
    Runs Io script with hookName in package's `hooks` directory if it exists.*/
    runHook := method(hook,
        f := File with("#{self dir}/hooks/#{hook}.io" interpolate)
        f exists ifTrue(
            Eerie log("Launching #{hook} hook for #{self name}", "debug")
            ctx := Object clone
            e := try(ctx doFile(f path))
            e catch(
                Eerie log("#{hook} failed.", "error")
                Eerie log(e message, "debug"))
            f close))
)

# Error types
Package do (
    //doc Package NotPackageError
    NotPackageError := Eerie Error clone setErrorMsg(
        "The directory '#{call evalArgAt(0)}' is not recognised as an Eerie "..
        "package.")

    //doc Package InsufficientManifestError
    InsufficientManifestError := Eerie Error clone \
        setErrorMsg("The manifest at '#{call evalArgAt(0)}' doesn't satisfy " ..
            "all requirements." .. 
            "#{if(call evalArgAt(1) isNil, " ..
                "\"\", \"\\n\" .. call evalArgAt(1))}")
)
