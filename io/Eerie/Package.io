//metadoc Package category API
//metadoc Package description Represents an Eerie package.

Package := Object clone do (

    //doc Package manifest Get the `Package Manifest`.
    manifest := nil

    //doc Package struct Get `Package Structure` for this package.
    struct := nil

    //doc Package packsio Get `Package PacksIo`.
    packsio := method(PacksIo with(self))

    /*doc Package versions
    Get `List` of available versions. The versions are collected from git tags.
    */
    versions := method(
        cmdOut := System sh("git tag", true, self struct root path)
        cmdOut stdout splitNoEmpties("\n") map(tag, Eerie SemVer fromSeq(tag)))

    /*doc Package dllFileName 
    Get the file name of the dynamic library provided by this package in the
    result of compilation with `lib` prefix.*/
    dllFileName := method("lib" .. self dllName .. "." .. Eerie dllExt)

    /*doc Package dllName 
    Get the name of the dynamic library provided by this package in the result
    of compilation. Note, this is the name of the library, not the name of the
    dll file (i.e. without extension and `lib` prefix). Use `Package
    dllFileName` for the DLL file name.*/
    dllName := method("Io" .. self manifest name)

    /*doc Package staticLibFileName 
    Get the file name of the static library provided by this package in the
    result of compilation.*/
    staticLibFileName := method("lib" .. self staticLibName .. ".a")

    /*doc Package staticLibName 
    Get the name of the static library provided by this package in the result of
    compilation. Note, this is the name of the library, not the name of the dll
    file (i.e. the extension and without `lib` prefix). Use `Package
    staticLibFileName` for the static library file name.*/
    staticLibName := method("Io" .. self manifest name)

    /*doc Package dllPath
    Get the path to the dynamic library this package represents.*/
    dllPath := method(self struct build dll path .. "/" .. self dllFileName)

    /*doc Package staticLibPath
    Get the path to the static library this package represents.*/
    staticLibPath := method(
        self struct build lib path .. "/" .. self staticLibFileName)

    # TODO
    # this should be removed and packsio should be used for linking or wherever
    # dependency lists is needed
    /*doc Package packages 
    Get the `List` of installed dependencies for this package.*/
    # packages := lazySlot(
        # self struct packs directories map(dir, Package with(dir path)))
    # XXX disabled it for now
    packages := list()

    /*doc Package global 
    Initializes the global Eerie package (i.e. the Eerie itself).*/
    global := lazySlot(Package with(Eerie root))

    /*doc Package with(path) 
    Creates new package from provided path (`Sequence`). 

    Raises `Package NotPackageError` if the directory is not an Eerie package.
    Use this to initialize a `Package`.*/
    with := method(path,
        klone := self clone
        klone struct := Structure with(path)
        klone _checksIsPackage

        manifestFile := File with(
            klone struct root path .. "/#{Eerie manifestName}" interpolate) 
        klone manifest := Manifest with(manifestFile)
        klone manifest validate

        # call to init the list
        klone packages
        klone)

    _checksIsPackage := method(
        if (self struct isPackage not, 
            Exception raise(NotPackageError with(self struct root path))))

    create := method(name, path,
        name
        # TODO inializes a new package
    )

    /*doc Package install(Structure)
    Install the package and its dependencies. The argument is 
    `Package Structure`.

    If the argument is `nil`, `self struct` is used.*/
    install := method(struct,
        if (struct isNil, struct = self struct)
        lock := Eerie TransactionLock clone
        lock lock
        self manifest packs foreach(dep, dep install(struct))
        lock unlock)

    update := method(
        # TODO
    )

    load := method(
        # TODO
    )

    //doc Package remove Removes self.
    remove := method(
        self struct root remove
        self packages := list())

    /*doc Package runHook(hookName) 
    Runs Io script with hookName in package's `hooks` directory if it exists.*/
    runHook := method(hook,
        f := File with("#{self struct root}/hooks/#{hook}.io" interpolate)
        f exists ifTrue(
            Logger log(
                "[[birghtBlue bold;Launching[[reset; #{hook} " ..
                "hook for #{self manifest name}")
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

)

//metadoc Manifest category Package
//metadoc Manifest description Represents parsed manifest file.
Package Manifest := Object clone do (

    //doc Manifest file Get `File` for this manifest.
    file := nil

    # manifest contet parsed as `Map`
    _map := nil

    //doc Manifest name Get package name.
    name := lazySlot(self _map at("name"))

    //doc Manifest version Returns version (`SemVer`) of the package.
    version := lazySlot(Eerie SemVer fromSeq(self _map at("version")))

    //doc Manifest description Get description.
    description := lazySlot(self _map at("description"))

    //doc Manifest branch Get git branch.
    branch := lazySlot(self _map at("branch"))

    /*doc Manifest packs
    Get the `List` of `Package Dependency` parsed from `"packs"` field in.*/
    packs := lazySlot(
        self _map at("packs") ifNilEval(list()) map(dep, 
            Package Dependency fromMap(dep)))

    //doc Manifest with(File) Init `Manifest` from file.
    with := method(file,
        klone := self clone
        klone file = file
        klone _map = file contents parseJson
        klone)

    /*doc Manifest validate(release) 
    Validates the manifest. If the `release` is `true`, validates for
    releasing/publishing.*/
    validate := method(release,
        self _checkRequired("name")
        self _checkRequired("version")
        self _checkRequired("author")
        self _checkRequired("url")

        # it's allowed to be empty for `protos`
        self _checkField(self _map at("protos") isNil,
            "The \"protos\" field is required.")

        self _checkType("protos", List)

        # `packs` is optional
        if (self _map at("packs") isNil or \
            self _map at("packs") isEmpty, return)

        self _checkType("packs", List)

        self _map at("packs") foreach(dep,
            self _checkField(
                dep at("name") isNil or dep at("name") isEmpty,
                "The \"packs[n].name\" is required.")

            self _checkField(
                dep at("version") isNil,
                "The \"packs[n].version\" is required."))

        if (release, self _validateRelease))

    # check's whether a field is not nil and not empty
    # the `field` argument is key with subfields separated by dot:
    # `foo.bar.baz`
    # the optional `msg` argument is the message, which will be shown on
    # invalid test
    _checkRequired := method(field, msg,
        value := self valueForKey(field)
        msg := msg ifNilEval(
            "The \"#{field}\" field is required and can't be empty." \
                interpolate)

        if (value isNil or value isEmpty,
            Exception raise(
                InsufficientManifestError with(self file path, msg))))

    /*doc Manifest valueForKey(key) 
    Get value for key (`Sequence`) in format where each field separated by
    dot: `foo.bar.baz`.*/
    valueForKey := method(key,
        split := key split(".")
        value := self _map
        split foreach(key, value = value at(key))
        value)

    _checkEither := method(first, second,
        valueA := self valueForKey(first)
        valueB := self valueForKey(second)
        msg := ("Either \"#{first}\" or \"#{second}\" field is required " .. 
            "and can't be empty.") interpolate

        if ((valueA isNil or valueA isEmpty) and \
            (valueB isNil or valueB isEmpty),
            Exception raise(
                InsufficientManifestError with(self file path, msg))))

    # check whether value specified by `key` is of type `input`
    _checkType := method(key, input,
        value := self valueForKey(key)
        msg := (
            "The field \"#{key}\" should be #{self _jsonTypeFor(input)}." \
                interpolate)

        if (value type != input type,
            Exception raise(
                InsufficientManifestError with(self file path, msg))))

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
                InsufficientManifestError with(self file path, msg))))

    _validateRelease := method(
        self _checkVersionShortened
        self _checkDescription
        self _checkReadme
        self _checkLicense)

    _checkVersionShortened := method(
        if (self version isShortened,
            Exception raise(VersionIsShortenedError with(self version asSeq))))

    _checkDescription := method(
        desc := self description
        if (desc isNil or desc isEmpty, 
            Exception raise(NoDescriptionError with(""))))

    _checkReadme := method(
        path := self valueForKey("readme")
        if (self _hasRequiredFile(path) not, 
            Exception raise(ReadmeError with(""))))

    _checkLicense := method(
        path := self valueForKey("license")
        if (self _hasRequiredFile(path) not, 
            Exception raise(LicenseError with(""))))

    _hasRequiredFile := method(path,
        if (path isNil or path isEmpty, return false)

        file := File with(self file parentDirectory path .. "/" .. path)
        
        (file exists not or file ?contents ?isEmpty) not)

)

# Manifest error types
Package Manifest do (

    //doc Manifest InsufficientManifestError
    InsufficientManifestError := Eerie Error clone setErrorMsg(
        "The manifest at #{call evalArgAt(0)} doesn't satisfy " ..
        "all requirements." .. 
        "#{if(call evalArgAt(1) isNil, " ..
            "\"\", \"\\n\" .. call evalArgAt(1))}")

    //doc Manifest VersionIsShortenedError
    VersionIsShortenedError := Eerie Error clone setErrorMsg(
        "The release version shouldn't be shortened.")

    //doc Manifest NoDescriptionError
    NoDescriptionError := Eerie Error clone setErrorMsg(
        "Published packages should have \"description\" in " ..
        "#{Eerie manifestName}.")

    //doc Manifest ReadmeError
    ReadmeError := Eerie Error clone setErrorMsg(
        "README file is required for published packages and shouldn't be " ..
        "empty.")

    //doc Manifest LicenseError
    LicenseError := Eerie Error clone setErrorMsg(
        "LICENSE file is required for published packages and shouldn't be " ..
        "empty.")

)

//metadoc Structure category Package
//metadoc Structure description Directory structure of `Package`.
Package Structure := Object clone do (

    //doc Structure root The root `Directory`.
    root := nil

    /*doc Structure bin
    The `bin` directory. `Directory` with binaries of the package.*/
    bin := method(self root directoryNamed("bin"))

    /*doc Structure binDest
    Get the `_bin` directory, where binaries of dependencies are installed.*/
    binDest := method(self root createSubdirectory("_bin"))

    /*doc Structure build
    Get object with `_build` directory structure.

    - `build root` - the `_build` root `Directory`
    - `build dll` - the output `Directory` for dynamic library the package
    represents
    - `build headers` - the `Directory` where all the headers of the package is
    installed
    - `build lib` - the output `Directory` for static library the package
    represents
    - `build objs` - the output `Directory for the compiled objects*/
    build := nil

    //doc Structure packs Get the `_packs` `Directory`.
    packs := method(self root createSubdirectory("_packs"))

    /*doc Structure source
    The `source` directory. The `Directory` with native (C) code.*/
    source := method(self root createSubdirectory("source"))

    /*doc Structure tmp
    Get `_tmp` `Directory`.*/
    tmp := method(self root createSubdirectory("_tmp"))

    //doc Structure buildio The `build.io` file.
    buildio := lazySlot(self root fileNamed("build.io"))

    /*doc Structure packRootFor(name)
    Get a directory for package name (`Sequence`) inside `packs` whether it's
    installed or not.*/ 
    packRootFor := method(name, self packs directoryNamed(name))

    /*doc Structure packFor(name, version)
    Get `Directory` for package inside `packs` for its name (`Sequence`) and
    version (`SemVer`).*/
    packFor := method(name, version,
        self packRootFor(name) directoryNamed(version asSeq))

    /*doc Structure with(rootPath) 
    Init `Structure` with the path to the root directory (`Sequence`).*/
    with := method(rootPath,
        klone := self clone
        klone root = Directory with(rootPath)
        klone build := BuildDir with(klone root)
        klone)

    /*doc Structure isPackage
    Returns boolean whether the structure is a `Package`.*/
    isPackage := method(
        ioDir := self root directoryNamed("io")
        manifest := File with(
            self root path .. "/#{Eerie manifestName}" interpolate)

        self root exists and manifest exists and ioDir exists)

    /*doc Structure hasNativeCode 
    Returns `true` if the structure has native code and `false` otherwise.*/
    hasNativeCode := method(
        self source files isEmpty not or self source directories isEmpty not)

    /*doc Structure hasBinaries
    Returns `true` if `self bin` has files and `false` otherwise.*/
    hasBinaries := method(self bin exists and self bin files isEmpty not)

    BuildDir := Object clone do (
        
        parent := nil

        with := method(parent,
            klone := self clone
            klone parent = parent
            klone)

        root := method(self parent createSubdirectory("_build"))

        dll := method(self root createSubdirectory("dll"))

        headers := method(self root createSubdirectory("headers"))

        lib := method(self root createSubdirectory("lib"))

        objs := method(self root createSubdirectory("objs"))

    )

)

//metadoc Dependency category Package
/*metadoc Dependency description 
Package dependency parsed from `"packs"` in `eerie.json`.*/
Package Dependency := Object clone do (

    //doc Dependency name Get name.
    name := nil

    //doc Dependency version Get version. Can be shortened.
    version := nil

    //doc Dependency url Get URL.
    url := nil

    //doc Dependency branch Get git branch.
    branch := nil

    /*doc Dependency fromMap(map)
    Initialize dependency from `Map` parsed from `"packs"` array items.*/
    fromMap := method(dep,
        klone := self clone
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

    The destination `Directory` is the root for the dependency. That means, for
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
    install := method(struct,
        struct packs createIfAbsent
        struct tmp createIfAbsent

        package := self _download(struct)

        version := self version highestIn(self package versions)

        installDir := struct packFor(self name, version)

        if (installDir exists, return)

        # install dependencies of dependency
        package install(struct)

        # install the dependency
        package manifest branch = self branch ifNilEval(package manifest branch)

        Installer with(
            package,
            installDir,
            struct binDest) install(version)

        struct tmp remove)

    # download the package and instantiate it
    _download := method(struct,
        if (self url isNil or self url isEmpty, 
            Exception raise(NoUrlError with(self name)))

        downloadDir := self _downloadDir(struct)

        if (downloadDir exists, return Package with(downloadDir path))

        downloader := Downloader detect(self url, downloadDir)
        downloader download

        Package with(downloader destDir))

    _downloadDir := method(struct,
        struct tmp \
            directoryNamed(self name) \
                directoryNamed(self version) \
                    createIfAbsent)

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
    file := method(self package struct root fileNamed("packs.io"))

    _descs := nil

    /*doc PacksIo with(package) 
    Init `PacksIo` with `Package`.*/
    with := method(package,
        klone := self clone
        klone package = package
        klone _descs := doFile(klone file path) ifNilEval(Map clone)
        klone)

    //doc PacksIo missing Get list of missing dependencies.
    missing := method(
        # TODO
    )

    /*doc PacksIo generate
    Generate the file.*/
    generate := method(
        self package manifest packs foreach(dep,
            self addDesc(Package DepDesc with(dep, self package struct)))

        self store)

    //doc PacksIo store Write the file.
    store := method(self file setContents(self _descs serialized))

    /*doc PacksIo addDesc(desc) 
    Add dependency description. If it's already in the map, replaces it with the
    passed one.*/
    addDesc := method(desc, self _descs atPut(desc name, desc))

    /*doc PacksIo removeDesc(name) 
    Remove dependency description by name (`Sequence`).*/
    removeDesc := method(name, self _descs removeAt(name))

)

//metadoc DepDesc category Package
/*metadoc DepDesc description
Description of an installed dependency. Serialization of this type is stored in
`packs.io`.*/
Package DepDesc := Object clone do (

    //doc DepDesc name Get name.
    //doc DepDesc setName(Sequence) Set name.
    name ::= nil

    //doc DepDesc version Get version (`Sequence`).
    //doc DepDesc setVersion Set version (`Sequence`).
    version ::= nil

    //doc DepDesc children Get children of this `DepDesc` (`Map`).
    //doc DepDesc setChildren(Map) Set children.
    children ::= nil

    //doc DepDesc parent Get parent `DepDesc`. Can return `nil`.
    //doc DepDesc setParent(DepDesc) Set parent.
    parent ::= nil 

    //doc DepDesc recursive Get a boolean whether `DepDesc` is recursive.
    //doc DepDesc setRecursive(boolean) `DepDesc recursive` setter.
    recursive ::= false

    /*doc DepDesc with(dep, struct, parent) 
    Recursively initializes `DepDesc` from `Package Dependency`, 
    `Package Structure` and parent `DepDesc` (can be `nil`).*/
    with := method(dep, struct, parent,
        depRoot := struct packRootFor(dep name)

        if (depRoot exists not,
            Exception raise(DependencyNotInstalledError with(dep name)))

        version := self _installedVersionFor(dep, depRoot)

        packDir := struct packFor(dep name, version)

        if (packDir exists not, 
            Exception raise(DependencyNotInstalledError with(dep name)))

        result := Package DepDesc clone \
            setName(dep name) \
                setVersion(version asSeq) \
                    setParent(parent)
                    
        result _collectChildren(packDir, struct))

    _installedVersionFor := method(dep, depRoot,
        versions := self _versionsInDir(depRoot)
        dep version highestIn(versions))

    # get list of `SemVer` in a package dir
    _versionsInDir := method(dir,
        dir directories map(subdir, SemVer fromSeq(subdir name)))

    _hasAncestor := method(desc,
        if (self parent isNil, return false)

        if (self parent name == desc name and(
            self parent version == desc version),
            return true,
            return self parent _hasAncestor(desc)))

    _collectChildren := method(packDir, struct,
        if (self _hasAncestor(self), return self setRecursive(true))

        deps := Package with(packDir path) manifest packs

        deps foreach(dep,
            self addChild(Package DepDesc with(dep, struct, self)))
    
        self)

    //doc DepDesc addChild(DepDesc) Adds a child.
    addChild := method(desc,
        if (self children isNil, self setChildren(Map clone))
        self children atPut(desc name, desc))

    //doc DepDesc removeChild(Sequence) Removes a child by its name.
    removeChild := method(name, 
        if (self children isNil, return)
        self children removeAt(name))

)

# PacksIo error types
Package DepDesc do (

    DependencyNotInstalledError := Eerie Error clone setErrorMsg(
        "Dependency \"#{call evalArgAt(0)}\" is not installed.")

)
