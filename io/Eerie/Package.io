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
        klone _checksIsPackage(Directory with(path))
        klone struct := Structure with(path)
        klone struct manifest validate

        # call to init the list
        klone packages
        klone)

    _checksIsPackage := method(root,
        if (Structure isPackage(root) not, 
            Exception raise(NotPackageError with(root path))))

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
