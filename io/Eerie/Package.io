//metadoc Package category API
//metadoc Package description Reprsents an Eerie package.
doRelativeFile("Path.io")

Package := Object clone do(
    //doc Package config
    config ::= nil

    //doc Package name
    name := method(self config at("name"))

    //doc Package setName(name)
    setName := method(v,
        self config atPut("name", v)
        self)

    //doc Package uri
    uri := method(self config at("uri"))

    //doc Package setUri
    setUri := method(v,
        self config atPut("uri", v)
        self)

    //doc Package path
    path := method(self config at("path"))

    //doc Package setPath(path)
    setPath := method(v,
        self config atPut("path", v)
        self)

    //doc Package installer Instace of [[PackageInstaller]] for this package.
    installer ::= nil
    //doc Package downloader Instance of [[PackageDownloader]] for this package.
    downloader ::= nil

    //doc Package info Contains all the data provided in package.json
    info := method(self loadInfo)

    init := method(
        self config = Map with(
            "name", nil,
            "uri",  nil,
            "path", nil))

    /*doc Package with(name, uri) Creates new package with provided name and 
    URI.*/
    with := method(name_, uri_,
        (uri_ exSlice(-1) == "/") ifTrue(
            uri_ = uri_ exSlice(0, -1))

        uri_ = Path absoluteIfNeeded(uri_)
        self clone setConfig(Map with(
            "name", name_,
            "uri",  uri_,
            "path", Eerie generatePackagePath(name_)))) 

    /*doc Package withConfig(config) Creates new package from provided config.*/
    withConfig := method(config,
        klone := self clone setConfig(config)

        klone config at("installer") isNil ifFalse(
            klone installer = Eerie PackageInstaller instances \
                getSlot(klone config at("installer")) \
                with(klone config at("path")))
        klone config at("downloader") isNil ifFalse(
            klone downloader = Eerie PackageDownloader instances \
                getSlot(klone config at("downloader")) \
                with(klone config at("uri"), klone config at("path")))

        klone)

    /*doc Package fromUri(uri) Creates a new package from provided uri.
    Name is determined with [[Package guessName]].*/
    fromUri := method(uri_, self with(self guessName(uri_), uri_))

    /*doc Package guessName(uri) Guesses name from provide URI. Usually it is
    just file's basename.*/
    guessName := method(uri_,
        (uri_ exSlice(-1) == "/") ifTrue(
            uri_ = uri_ exSlice(0, -1))

        f := File with(uri_)
        # We can't use baseName here because it returns nil for directories
        if(f exists,
            f name split("."),
            uri_ split("/") last split(".")) first makeFirstCharacterUppercase)

    //doc Package setInstaller(packageInstaller)
    setInstaller := method(inst,
        self installer = inst
        self config atPut("installer", inst type)
        self)

    //doc Package setDownloader(packageDownloader)
    setDownloader := method(downl,
        self downloader := downl
        self config atPut("downloader", downl type)
        self)

    /*doc Package runHook(hookName) Runs Io script with hookName in package's
    `hooks` directory if it exists.*/
    runHook := method(hook,
        f := File with("#{self path}/hooks/#{hook}.io" interpolate)
        f exists ifTrue(
            Eerie log("Launching #{hook} hook for #{self name}", "debug")
            ctx := Object clone
            e := try(ctx doFile(f path))
            e catch(
                Eerie log("#{hook} failed.", "error")
                Eerie log(e message, "debug"))
            f close))

    //doc Package loadInfo Loads package.json file.
    loadInfo := method(
        pkgInfo := File with((self path) .. "/package.json")
        self info = if(pkgInfo exists,
            pkgInfo openForReading contents parseJson,
            Map clone)

        pkgInfo close
        self info)

    //doc Package providesProtos Returns list of protos this package provides.
    providesProtos := method(
        p := self info at("protos")
        if(p isNil, list(), p))

    /*doc Package dependencies([category])
    Returns list of dependencies this package has. <code>category</code> can be 
    <code>protos</code>, <code>packages</code>, <code>headers</code> or 
    <code>libs</code>.*/
    dependencies := method(category,
        d := self info at("dependencies")
        if(category and d and d isEmpty not, d = d at(category))
        if(d isNil, list(), d))

    //doc Package asJson Returns config.
    asJson := method(self config)
)
