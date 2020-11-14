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
    Returns boolean whether the package is recursive dependency.

    See `Package initRecursive`*/
    recursive := false

    /*doc Package initRecursive(Package, Package)
    Init a recursive `Package`.

    Recursive `Packages` represent recursive dependencies in the children
    tree.

    The first argument is the package this package is recursion of.

    The second argument is the parent package.*/
    initRecursive := method(package, parent,
        klone := self clone
        klone recursive = true
        klone struct = package struct
        klone parent = parent
        klone children = package children
        klone)

    /*doc Package global 
    Initializes the global Eerie package (i.e. the Eerie itself).*/
    global := lazySlot(Package with(Eerie root))

    /*doc Package with(path)
    Creates new package from provided path (`Sequence`). 

    Raises `Package NotPackageError` if the directory is not an Eerie package.
    Use this to initialize a `Package`.*/
    # `_topStruct` is used internally to pass the top level Package Structure
    # for children initialization
    with := method(path, _topStruct,
        klone := self clone
        klone _checkIsPackage(Directory with(path))
        klone struct := Structure with(path)
        klone struct manifest validate
        klone children := Map clone
        klone _initChildren(_topStruct)

        klone)

    _checkIsPackage := method(root,
        if (Structure isPackage(root) not, 
            Exception raise(NotPackageError with(root path))))

    _initChildren := method(topStruct,
        if (topStruct isNil, topStruct = self struct)
        self struct manifest packs foreach(dep, 
            self _addChildFromDep(dep, topStruct)))

    _addChildFromDep := method(dep, struct,
        depRoot := struct packRootFor(dep name)

        if (depRoot exists not, return)

        version := self _installedVersionFor(dep, depRoot)

        packDir := struct packFor(dep name, version)

        if (packDir exists not, return)

        ancestor := self _ancestor(dep name, version)

        package := if (ancestor isNil not, 
            Package initRecursive(ancestor, self),
            Package clone setParent(self) with(packDir path, struct))

        self addChild(package))

    _installedVersionFor := method(dep, depRoot,
        versions := self _versionsInDir(depRoot)
        dep version highestIn(versions))

    # get list of `SemVer` in a package dir
    _versionsInDir := method(dir,
        dir directories map(subdir, SemVer fromSeq(subdir name)))

    _ancestor := method(name, version,
        if (self parent isNil, return nil)

        if (self parent struct manifest name == name and \
            self parent struct manifest version == version,
            return self parent,
            return self parent _ancestor(name, version)))

    //doc Package addChild(Package) Adds a child `Package`.
    addChild := method(package,
        self children atPut(package struct manifest name, package))

    //doc Package removeChild(Sequence) Removes a child `Package` by its name.
    removeChild := method(name, self children removeAt(name))

    /*doc Package missing 
    Returns list of missing dependencies (`Manifest Dependency`).*/
    missing := method(
        self struct manifest packs select(name, dep, 
            self children hasKey(name) not) values)

    /*doc Package changed
    Get list of dependencies (`Manifest Dependency`), which requirements has
    been changed in `eerie.json`.

    Currently only "version" is supported.*/
    changed := method(
        self struct manifest packs select(name, pack,
            child := self children at(name)

            if (child isNil, return false)

            # TODO the user can change other parameters like url or branch, for
            # example
            # for now we can't compare them, because we don't have a snapshot of
            # packages (a "package-lock file"). Because, if we take the URL
            # inside package, then there could be a problem when the user
            # is the developer of the dependency and in "packs" the "url" is a
            # local directory, but for a published package the url is different.
            # The same for "branch". The default git branch for package can be
            # different from the user's requirements.
            pack version includes(child struct manifest version) not) values)

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
        self parent ?removeChild(self struct manifest name))

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
