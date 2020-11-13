//metadoc Package category API
//metadoc Package description Represents an Eerie package.

Package := Object clone do (

    doRelativeFile("Package/Structure.io")

    //doc Package struct Get `Package Structure` for this package.
    struct := nil

    /*doc Package versions
    Get `List` of available versions. The versions are collected from git tags.
    */
    versions := method(
        cmdOut := System sh("git tag", true, self struct root path)
        cmdOut stdout splitNoEmpties("\n") map(tag, Eerie SemVer fromSeq(tag)))

    /*doc Package parent 
    Get parent of this `Package`. Returns `nil` if it's top-level.*/
    //doc Package setParent(Package) Set parent for this package.
    parent ::= nil

    /*doc Package children 
    Get `Map` of installed children (`Package`'s) of this package.*/
    children := nil

    /*doc Package recursive
    Returns boolean whether the package is recursive dependency.*/
    recursive := false

    /*doc Package packages 
    Get the `List` of installed dependencies (`Package`) for this package.*/
    packages := method(
        self struct packsio descs map(name, desc,
            Package with(
                self struct packFor(desc name, SemVer fromSeq(desc version)))))

    /*doc Package global 
    Initializes the global Eerie package (i.e. the Eerie itself).*/
    global := lazySlot(Package with(Eerie root))

    /*doc Package with(path) 
    Creates new package from provided path (`Sequence`). 

    Raises `Package NotPackageError` if the directory is not an Eerie package.
    Use this to initialize a `Package`.*/
    with := method(path,
        klone := self clone
        klone _checksIsPackage(Directory with(path))
        klone struct := Structure with(path)
        klone struct manifest validate
        klone children := Map clone
        # klone _initChildren

        klone)

    _checksIsPackage := method(root,
        if (Structure isPackage(root) not, 
            Exception raise(NotPackageError with(root path))))

    _initChildren := method(
        self struct manifest packs foreach(dep, self _addChildFromDep(dep)))

    _addChildFromDep := method(dep,
        depRoot := self struct packRootFor(dep name)

        if (depRoot exists not, return)

        version := self _installedVersionFor(dep, depRoot)

        packDir := struct packFor(dep name, version)

        if (packDir exists not, return)

        # TODO detect recursive dependencies and make aliases for them
        # FIXME directory structure is related to newly initialized package

        # look PacksIo DepDesc for implementation reference
    )

    _installedVersionFor := method(dep, depRoot,
        versions := self _versionsInDir(depRoot)
        dep version highestIn(versions))

    # get list of `SemVer` in a package dir
    _versionsInDir := method(dir,
        dir directories map(subdir, SemVer fromSeq(subdir name)))

    //doc Package addChild(Package) Add a child `Package`.
    addChild := method(package, self children atPut(package name, package))

    /*doc Package missing 
    Returns list of missing dependencies (`Manifest Dependency`).*/
    missing := method(
        self struct manifest packs select(name, 
            self children hasKey(name) not))

    /*doc Package abandoned
    Returns list of abandoned dependencies (`Package`) (i.e. those which are no
    more in `eerie.json`).*/
    abandoned := method(
        self children select(name,
            self struct manifest packs hasKey(name) not))

    /*doc Package changed
    Get list of dependencies (`Manifest Dependency`), which requirements has
    been changed in `eerie.json`.*/
    changed := method(
        self struct manifest packs select(name, pack,
            child := self children at(name)

            if (child isNil, return false)

            pack version includes(child version) not or pack url != child url))

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
        self struct manifest packs foreach(dep, dep install(struct))
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
                "hook for #{self struct manifest name}")
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
