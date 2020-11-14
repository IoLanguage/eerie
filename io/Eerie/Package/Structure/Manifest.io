//metadoc Manifest category Package
//metadoc Manifest description Represents parsed manifest file.
Manifest := Object clone do (

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
    Get the `Map` of `Dependency` parsed from `"packs"` field in.*/
    packs := lazySlot(
        result := Map clone
        self _map at("packs") ?foreach(value, 
            dep := Dependency fromMap(value)
            result atPut(dep name, dep))
        result)

    //doc Manifest with(File) Init `Manifest` from file.
    with := method(file,
        klone := self clone
        klone file = file
        if (file exists not,
            Exception raise(FileNotExistsError with(file path)))
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
Manifest do (

    //doc Manifest FileNotExistsError
    FileNotExistsError := Eerie Error clone setErrorMsg(
        "The manifest file at '#{call evalArgAt(0)}' doesn't exist.")

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

//metadoc Dependency category Package
/*metadoc Dependency description 
Package dependency parsed from `"packs"` in `eerie.json`.*/
Manifest Dependency := Object clone do (

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
        package struct manifest branch = self branch ifNilEval(
            package struct manifest branch)

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

Manifest Dependency do (

    NoUrlError := Eerie Error clone setErrorMsg(
        "URL for #{call evalArgAt(0)} is not found.")

)
