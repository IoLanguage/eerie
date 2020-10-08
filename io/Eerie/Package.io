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

    /*doc Package withConfig(config) Creates new package from provided config.*/
    withConfig := method(config,
        klone := self clone setConfig(config)
        klone)

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

)
