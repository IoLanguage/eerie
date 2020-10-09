//metadoc Package category API
//metadoc Package description Reprsents an Eerie package.
doRelativeFile("Path.io")
doRelativeFile("SemVer.io")

Package := Object clone do (
    //doc Package config Package's config file (the manifest) as a `Map`.
    config ::= nil

    //doc Package dir Directory of this package.
    dir ::= nil

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

    //doc Package installer Instace of [[PackageInstaller]] for this package.
    installer := method(self installer = PackageInstaller with(self))

    //doc Package downloader Instance of [[PackageDownloader]] for this package.
    downloader ::= nil

    /*doc Package with(dir) 
    Creates new package from provided `Directory`. Raises `NotPackageException`
    if the directory is not an Eerie package. Use this to init a `Package`.*/
    with := method(dir,
        Eerie log("Init package with dir #{dir}", "debug")
        _checkDirectoryPackage(dir)

        klone := self clone setDir(dir)
        manifest := File with(dir path .. "/#{Eerie manifestName}" interpolate) 
        klone setConfig(manifest contents parseJson)
        klone setVersion(SemVer fromSeq(klone config at("version")))
        klone)

    _checkDirectoryPackage := method(dir,
        Eerie log("Checking directory package #{dir}", "debug")
        ioDir := dir directoryNamed("io")
        manifest := File with(dir path .. "/#{Eerie manifestName}" interpolate)
        if ((dir exists and manifest exists and ioDir exists) not,
            Eerie NotPackageException raise(dir path))

        self _validateManifest(manifest))

    _validateManifest := method(manifest,
        Eerie log("Validating manifest #{manifest path}", "debug")
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
        test ifTrue(Eerie InsufficientManifestException raise(list(path, msg))))


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

    /*doc Package runHook(hookName) Runs Io script with hookName in package's
    `hooks` directory if it exists.*/
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
