//metadoc Package category API
//metadoc Package description Represents an Eerie package.

Package := Object clone do (

    //doc Package manifestName The name of the manifest file.
    manifestName := "eerie.json"
    
    //doc Package config Package's config file (the manifest) as a `Map`.
    config ::= nil

    //doc Package name
    name := method(self config at("name"))

    //doc Package version Returns parsed version (`SemVer`) of the package.
    version ::= nil

    /*doc Package versions
    Get `List` of available versions. The versions are collected from git tags.
    */
    versions := method(
        cmdOut := System sh("git tag", true, self dir path)
        cmdOut stdout splitNoEmpties("\n") map(tag, Eerie SemVer fromSeq(tag)))

    //doc Package branch Get git branch for this package.
    //doc Package setBranch(Sequence) Set git branch for this package.
    branch ::= lazySlot(self config at("branch"))

    /*doc Package deps
    Get the `List` of `Package Dependency` parsed from `"packs"` field in
    `eerie.json`.*/
    deps := lazySlot(
        self config at("packs") map(dep, Dependency fromMap(dep, self)))

    /*doc Package depNamed 
    Get `Package Dependency` from `Package deps` with the given name (if
    any).*/
    depNamed := method(name, self deps detect(dep, dep name == name))

    //doc Package dir Directory of this package.
    dir ::= nil

    /*doc Package sourceDir 
    The `source` directory. The `Directory` with native (C) code.*/
    sourceDir := method(self dir createSubdirectory("source"))

    /*doc Package binDir 
    The `bin` directory. `Directory` with binaries of the package.*/
    binDir := lazySlot(self dir directoryNamed("bin"))

    /*doc Package destBinDir
    Get the `_bin` directory, where binaries of dependencies are installed.*/
    destBinDir := method(self dir createSubdirectory("_bin"))

    //doc Package packsDir Get the `_packs` `Directory`.
    packsDir := method(self dir createSubdirectory("_packs"))

    //doc Package packsIo Get `Package PacksIo`.
    packsIo := method(PacksIo with(self))

    /*doc Package packRootFor 
    Get a directory for package name (`Sequence`) inside `packsDir` whether
    it's installed or not.*/ 
    packRootFor := method(name, self packsDir directoryNamed(name))

    /*doc Package tmpDir 
    Get `_tmp` `Directory`, the temporary directory used by `Downloader` to
    download dependencies into.*/
    tmpDir := method(self dir createSubdirectory("_tmp"))

    /*doc Package buildDir 
    Get `_build` `Directory`, the directory where build artifacts are stored.*/
    buildDir := method(self dir createSubdirectory("_build"))

    /*doc Package headersBuildDir
    Get the output `Directory` where all the headers of this package will be
    installed.*/
    headersBuildDir := method(self buildDir createSubdirectory("headers"))

    /*doc Package objsBuildDir
    Get the output objects (`.o`) `Directory`.*/
    objsBuildDir := method(self buildDir createSubdirectory("objs"))

    /*doc Package dllBuildDir
    Get the output `Directory` for dynamic library this package represents.*/
    dllBuildDir := method(self buildDir createSubdirectory("dll"))

    /*doc Package staticLibBuildDir
    Get the output `Directory` for static library this package represents.*/
    staticLibBuildDir := method(self buildDir createSubdirectory("lib"))

    /*doc Package dllFileName 
    Get the file name of the dynamic library provided by this package in the
    result of compilation with `lib` prefix.*/
    dllFileName := method("lib" .. self dllName .. "." .. Eerie dllExt)

    /*doc Package dllName 
    Get the name of the dynamic library provided by this package in the result
    of compilation. Note, this is the name of the library, not the name of the
    dll file (i.e. without extension and `lib` prefix). Use `Package
    dllFileName` for the DLL file name.*/
    dllName := method("Io" .. self name)

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

    /*doc Package packages 
    Get the `List` of installed dependencies for this package.*/
    packages := lazySlot(
        self packsDir directories map(dir, Package with(dir path)))

    /*doc Package global 
    Initializes the global Eerie package (i.e. the Eerie itself).*/
    global := lazySlot(Package with(Eerie root))

    /*doc Package with(path) 
    Creates new package from provided path (`Sequence`). Raises
    `NotPackageError` if the directory is not an Eerie package. Use this to
    initialize a `Package`.*/
    with := method(path,
        klone := self clone setDir(Directory with(path))
        _checkDirectoryPackage(klone dir)

        manifest := File with(
            klone dir path .. "/#{Package manifestName}" interpolate) 
        klone setConfig(manifest contents parseJson)
        klone setVersion(Eerie SemVer fromSeq(klone config at("version")))
        # call to init the list
        klone packages
        klone)

    _checkDirectoryPackage := method(dir,
        ioDir := dir directoryNamed("io")
        manifest := File with(
            dir path .. "/#{Package manifestName}" interpolate)
        if ((dir exists and manifest exists and ioDir exists) not,
            Exception raise(NotPackageError with(dir path)))

        ManifestValidator with(manifest) validate)

    /*doc Package highestVersionFor(version) 
    Returns the highest available `SemVer` for `version` (`SemVer`). If
    `version` is `nil` returns the highest version in the `Package versions`.

    Returns `nil` if `Package versions` is empty.*/
    highestVersionFor := method(version,
        versions := self versions

        if (self versions isEmpty, return nil)

        if (version isNil, return self _highestVersion(versions))

        result := version
        versions foreach(ver, 
            if (ver <= version and ver isPre == version isPre, 
                result = ver))

        result)

    _highestVersion := method(versions,
        result := versions at(0)

        versions foreach(ver,
            if (ver > result, result = ver))

        result)

    /*doc Package hasNativeCode 
    Returns `true` if the package has native code and `false` otherwise.*/
    hasNativeCode := method(
        self sourceDir files isEmpty not or(
            self sourceDir directories isEmpty not))

    /*doc Package hasBinaries
    Returns `true` if the `Package binDir` has files and `false` otherwise.*/
    hasBinaries := method(self binDir exists and self binDir files isEmpty not)

    /*doc Package checkHasDep(name)
    Check whether the package has dependency (i.e. in eerie.json) with the
    specified name (`Sequence`).

    Raises `Package NoDependencyError` if it doesn't.*/
    checkHasDep := method(depName,
        if (self depNamed(depName) isNil,
            Exception raise(NoDependencyError with(self name, depName))))

    /*doc Package install(destination)
    Install the package and its dependencies into the `destination` `Directory`.

    If the `destination` is `nil`, `self packsDir` is used.*/
    install := method(destDir,
        if (destDir isNil, destDir = self packsDir)
        lock := Eerie TransactionLock clone
        lock lock
        self deps foreach(dep, dep install(destDir))
        lock unlock)

    //doc Package remove Removes self.
    remove := method(
        self dir remove
        self packages := list())

    /*doc Package runHook(hookName) 
    Runs Io script with hookName in package's `hooks` directory if it exists.*/
    runHook := method(hook,
        f := File with("#{self dir}/hooks/#{hook}.io" interpolate)
        f exists ifTrue(
            Logger log(
                "[[birghtBlue bold;Launching[[reset; #{hook} " ..
                "hook for #{self name}")
            ctx := Object clone
            e := try(ctx doFile(f path))
            f close
            e catch(Exception raise(FailedRunHookError with(hook, e message)))))


)

# Error types
Package do (

    //doc Package NotPackageError
    NotPackageError := Eerie Error clone setErrorMsg(
        "The directory '#{call evalArgAt(0)}' is not recognised as an Eerie "..
        "package.")

    //doc Package FailedRunHookError
    FailedRunHookError := Eerie Error clone setErrorMsg(
        "Failed run hook \"#{call evalArgAt(0)}\":\n#{call evalArgAt(1)}")

    //doc Package NoDependencyError
    NoDependencyError := Eerie Error clone setErrorMsg(
        "The package \"#{call evalArgAt(0)}\" has no dependency " .. 
        "\"#{call evalArgAt(1)}\" in #{Package manifestName}.")

)

//metadoc Dependency category Package
/*metadoc Dependency description 
Package dependency parsed from `"packs"` in `eerie.json`.*/
Package Dependency := Object clone do (

    //doc Dependency name Get name.
    name := nil

    //doc Dependency version Get version. Can be shortened.
    version := nil

    //doc Dependency parentPkg The parent `Package` of this dependency.
    parentPkg := nil

    //doc Dependency url Get URL.
    url := nil

    //doc Dependency branch Get git branch.
    branch := nil

    /*doc Dependency fromMap(map, parentPkg)
    Initialize dependency from `Map` parsed from `"packs"` array items.*/
    fromMap := method(dep, parentPkg,
        klone := self clone
        klone parentPkg = parentPkg
        klone name = dep at("name")
        klone version = Eerie SemVer fromSeq(dep at("version"))
        # if url is nil the pack supposed to be in the db, so we try to get it
        # from there
        klone url = dep at("url") ifNilEval(
            Eerie database valueFor(klone name, "url"))
        klone branch = dep at("branch")
        klone)

    /*doc Dependency install(Directory)
    Download and install the dependency this `Dependency` describes to the
    destination root `Directory`. 

    The destination `Directory` is the root for the depdency. That means, for
    dependency **A** with version **1.0.0** and destination `foo/bar`, the
    package will be installed in: `foo/bar/A/1.0.0`.*/

    # There are two scenarios for `branch` configuration:
    # 
    # 1. The user can specify branch per dependency in `packs`:
    # ```
    # ...
    # "packs": [
    #   {
    #      ...
    #      "branch": "develop"
    #   }
    # ]
    # ...
    # 
    # ```
    # 
    # 2. The developer can specify main `"branch"` for the package.
    # 
    # The first scenario has more priority, so we try to get the user specified
    # branch first and then if it's `nil` we check the developer's one.
    install := method(destDir,
        destDir createIfAbsent

        package := self _download

        installDir := self _installDir(destDir, package version)

        if (installDir exists, return)

        # install dependencies of dependency
        package install(destDir)

        # install the dependency
        self _installPackage(package, installDir)

        self parentPkg tmpDir remove)

    # download the package and instantiate it
    _download := method(
        if (self url isNil or self url isEmpty, 
            Exception raise(NoUrlError with(self name)))

        if (self _downloadDir exists, return Package with(self _downloadDir))

        downloader := Downloader detect(self url, self _downloadDir)
        downloader download

        Package with(download destDir))

    _downloadDir := lazySlot(
        self parentPkg tmpDir \
            directoryNamed(self name) \
                directoryNamed(self version))

    _installDir := method(destDir, version,
        destDir directoryNamed(self name) directoryNamed(version))

    _installPackage := method(package, installDir,
        package branch = self branch ifNilEval(package branch)

        installer := Installer with(
            package, 
            installDir,
            self parentPkg destBinDir)

        installer install(self version))

)

Package Dependency do (

    NoUrlError := Eerie Error clone setErrorMsg(
        "URL for #{call evalArgAt(0)} is not found.")

)

//metadoc PacksIo category Package
//metadoc PacksIo description Represents `packs.io` file.
Package PacksIo := Object clone do (

    //doc PacksIo package Get the `Package`.
    package := nil

    //doc PacksIo file Get `packs.io` `File`.
    file := method(self package dir fileNamed("packs.io"))

    _descs := Map clone

    /*doc PacksIo with(package) 
    Init `PacksIo` with `Package`.*/
    with := method(package,
        klone := self clone
        klone package = package
        klone)

    //doc PacksIo missing Get list of missing dependencies.
    missing := method(
        # TODO
    )

    /*doc PacksIo generate
    Generate the file.*/
    generate := method(
        self package deps foreach(dep,
            # TODO we should generate subdependencies as well
            depRoot := self package packRootFor(dep name)
            if (depRoot exists not,
                Exception raise(
                    DependencyNotInstalledError with(dep name, self package)))

            version := self _highestVersionFor(dep)

            self addDesc(
                DepDesc clone setName(dep name) setVersion(dep version asSeq))))

    _highestVersionFor := method(dep,
        dep
        # TODO
    )

    /*doc PacksIo replaceDesc(desc) 
    Replace the same named dependency description with the passed one.*/
    replaceDesc := method(desc,
        self removeDesc(desc name)
        self addDesc(desc))

    //doc PacksIo addDesc(desc) Add dependency description to the file.
    addDesc := method(desc,
        desc
        # TODO
        # if desc is already in file don't do anything, otherwise add
    )

    removeDesc := method(name,
        name
        # TODO
    )

    DepDesc := Object clone do (
        
        name ::= nil

        version ::= nil

    )

)

# PacksIo error types
Package PacksIo do (

    DependencyNotInstalledError := Eerie Error clone setErrorMsg(
        "Dependency \"#{call evalArgAt(0)}\" of package " ..
        "\"#{call evalArgAt(1)}\" is not installed.")

)

//metadoc ManifestValidator category Package
//metadoc ManifestValidator description Validates `eerie.json`.
Package ManifestValidator := Object clone do (

    _manifest := nil

    _config := nil
    
    //doc ManifestValidator with(File) Init validator with given manifest.
    with := method(manifest,
        klone := self clone
        klone _manifest := manifest
        klone _config := manifest contents parseJson
        klone)

    //doc ManifestValidator validate Validates the manifest.
    validate := method(
        self _checkRequired("name")
        self _checkRequired("version")
        self _checkRequired("author")
        self _checkRequired("url")

        # it's allowed to be empty for `protos`
        self _checkField(self _config at("protos") isNil,
            "The \"protos\" field is required.")

        self _checkType("protos", List)

        # `packs` is optional
        if (self _config at("packs") isNil or \
            self _config at("packs") isEmpty, return)

        self _checkType("packs", List)

        self _config at("packs") foreach(dep,
            self _checkField(
                dep at("name") isNil or dep at("name") isEmpty,
                "The \"packs[n].name\" is required.")

            self _checkField(
                dep at("version") isNil,
                "The \"packs[n].version\" is required.")))

        # check's whether a field is not nil and not empty
        # the `field` argument is key with subfields separated by dot:
        # `foo.bar.baz`
        # the optional `msg` argument is the message, which will be shown on
        # invalid test
        _checkRequired := method(field, msg,
            value := self _valueForKey(field)
            msg := msg ifNilEval(
                "The \"#{field}\" field is required and can't be empty." \
                    interpolate)

            if (value isNil or value isEmpty,
                Exception raise(
                    InsufficientManifestError with(self _manifest path, msg))))

        # get config value for key of type `foo.bar.baz`
        _valueForKey := method(key,
            split := key split(".")
            value := self _config
            split foreach(key, value = value at(key))
            value)

        _checkEither := method(first, second,
            valueA := self _valueForKey(first)
            valueB := self _valueForKey(second)
            msg := ("Either \"#{first}\" or \"#{second}\" field is required " .. 
                "and can't be empty.") interpolate

            if ((valueA isNil or valueA isEmpty) and \
                (valueB isNil or valueB isEmpty),
                Exception raise(
                    InsufficientManifestError with(self _manifest path, msg))))

        # check whether value specified by `key` is of type `input`
        _checkType := method(key, input,
            value := self _valueForKey(key)
            msg := (
                "The field \"#{key}\" should be #{self _jsonTypeFor(input)}." \
                    interpolate)

            if (value type != input type,
                Exception raise(
                    InsufficientManifestError with(self _manifest path, msg))))

        # get json type name for argument type
        _jsonTypeFor := method(input,
            if (input type == Map type) then (
                return "an object"
            ) elseif (input type == List type) then (
                return "an array"
            ) elseif (input type == Number type) then (
                return "a number"
            ) elseif (input type == Sequence type) then (
                return "a string"
            ) elseif (input type == true type or input type == false type) \
                then (
                    return "a boolean"
            ) elseif (input type == nil type) then (
                return "null"
            ) else (
                return "undefined"))

        # the first argument is a boolean. If it's `true`,
        # `InsufficientManifestError` will raise with the message at the second
        # argument.
        _checkField := method(test, msg,
            test ifTrue(
                Exception raise(
                    InsufficientManifestError with(self _manifest path, msg))))

)

# ManifestValidator error types
Package ManifestValidator do (

    //doc ManifestValidator InsufficientManifestError
    InsufficientManifestError := Eerie Error clone setErrorMsg(
        "The manifest at #{call evalArgAt(0)} doesn't satisfy " ..
        "all requirements." .. 
        "#{if(call evalArgAt(1) isNil, " ..
            "\"\", \"\\n\" .. call evalArgAt(1))}")

)
