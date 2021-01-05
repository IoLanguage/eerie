//metadoc Package category API
//metadoc Package description Represents an Eerie package.

Package := Object clone do (

    doRelativeFile("Package/Structure.io")

    //doc Package struct Get `Package Structure` for this package.
    struct := nil

    /*doc Package versions
    Get `List` of available versions. The versions are collected from git tags.
    */
    versions := lazySlot(
        cmdOut := System sh("git tag", true, self struct root path)
        vers := cmdOut stdout splitNoEmpties("\n")
        # if (vers isEmpty, return list(self struct manifest version))
        vers map(tag, Eerie SemVer fromSeq(tag)))

    /*doc Package parent 
    Get parent of this `Package`. Returns `nil` if it's top-level.*/
    //doc Package setParent(Package) Set parent for this package.
    parent ::= nil

    /*doc Package children 
    Get `Map` of installed children (`Package`'s) of this package.*/
    children := method(self rebuildChildren children)

    /*doc Package recursive
    Returns boolean whether the package is recursive dependency.

    See `Package initRecursive`*/
    recursive := false

    # Map used to track Manifest Dependency to install
    _installCache := nil

    # Map used to track Manifest Dependency to update
    _updateCache := nil

    # this Map is used to load each particular version of a package only once
    _loadingCache := nil

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

    /*doc Package with(path, parent)
    Creates new package from provided path (`Sequence`).

    `parent` is optional `Parent` package.

    Raises `Package NotPackageError` if the directory is not an Eerie package.
    Use this to initialize a `Package`.*/
    with := method(path, parent,
        klone := self clone
        klone _checkIsPackage(Directory with(path))
        klone struct := Structure with(path)
        klone struct manifest validate
        klone parent = parent

        klone)

    _checkIsPackage := method(root,
        if (Structure isPackage(root) not, 
            Exception raise(NotPackageError with(root path))))

    /*doc Package rebuildChildren(Package)
    Rebuild the package `children` tree. The argument is the top level parent
    package. If the argument is `nil`, `self` is used.*/
    rebuildChildren := method(topParent,
        self children := Map clone
        topParent = topParent ifNilEval(self)
        self struct manifest packs foreach(dep, 
            self _addChildFromDep(dep, topParent))
        self)

    _addChildFromDep := method(dep, topParent,
        depRoot := topParent struct packRootFor(dep name)

        if (depRoot exists not, return)

        version := self _installedVersionFor(dep, depRoot)

        packDir := topParent struct packFor(dep name, version)

        if (packDir exists not, return)

        ancestor := self _ancestor(dep name, version)

        package := if (ancestor isNil not, 
            Package initRecursive(ancestor, self),
            Package with(packDir path, self) rebuildChildren(topParent))

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

            if (child isNil, continue)

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

    /*doc Package create(name[, path])
    Initialize a new package with `name` (`Sequence`) at optional `path`
    (`Sequence`). If `path` isn't specified, will create a directory with
    `name` relative to current directory.

    Returns a `Package`.*/
    create := method(name, path,
        path = path ifNilEval(Directory currentWorkingDirectory)
        path = Path with(path, name)

        username := self _username

        dir := self _createDirStructure(name, username, path)

        self _createManifest(name, username, path)

        self _createGitignore(path)

        System sh("git init", false, path)

        Package with(path))

    _username := method(
        if (Eerie isWindows,
            System getEnvironmentVariable("USERNAME"),
            System getEnvironmentVariable("USER")))

    _createDirStructure := method(name, username, path,
        dir := Directory with(path)
        dir createIfAbsent
        dir createSubdirectory("io")
        file := dir directoryNamed("io") fileNamed("#{name}.io" interpolate)
        file create
        file setContents((
            "//metadoc #{name} category API\n" ..
            "//metadoc #{name} author #{username}\n" ..
            "//metadoc #{name} description The package description.\n" ..
            "\n" ..
            "#{name} := Object clone"
        ) interpolate)
        dir)

    _createManifest := method(name, username, path,
        manifest := File with(Path with(path, Structure Manifest fileName))
        manifest create

        manifest setContents((
            "{\n" .. 
            "    \"name\": \"#{name}\",\n" ..
            "    \"version\": \"0.1.0\",\n" .. 
            "    \"author\": \"#{username}\",\n" ..
            "    \"url\": \"#{path}\"\n" ..
            "}") interpolate))

    _createGitignore := method(path,
        gitignore := File with(Path with(path, ".gitignore"))
        gitignore create
        gitignore setContents(
            ".DS_Store\n" .. 
            "_bin\n" ..
            "_build\n" ..
            "_packs"))

    /*doc Package install
    Install the package and its dependencies.*/
    install := method(
        lock := Eerie TransactionLock with(self struct root path)
        lock lock
        self _installCache := Map clone
        self _updateCache := Map clone
        self _resolveDeps(self)
        self rebuildChildren
        Builder with(self) build
        self struct build tmp remove
        lock unlock)

    _resolveDeps := method(topParent,
        deps := self _unresolvedDeps(
            self missing appendSeq(self _removeChanged),
            topParent,
            topParent _installCache)

        if (deps isEmpty not,
            Logger log("[[cyan bold;Resolving [[reset;dependencies for " ..
                "#{self struct manifest name} " .. 
                "v#{self struct manifest version asSeq}", 
                "output"))

        deps foreach(dep, dep install(topParent, self)))

    # returns list of unresolved deps in the given list of deps
    _unresolvedDeps := method(deps, topParent, cache,
        deps select(dep,
            result := cache hasKey(self _depCacheKey(dep)) not
            cache atPut(self _depCacheKey(dep), dep)
            result))

    _removeChanged := method(
        changed := self changed ifNilEval(list())
        changed foreach(dep, self children at(dep name) ?remove)
        changed)

    _depCacheKey := method(dep, dep name .. "@" .. dep version asSeq)

    /*doc Package update
    Updates all dependencies of the package.*/
    update := method(
        self _checkMissing(self)
        lock := Eerie TransactionLock with(self struct root path)
        lock lock
        self _installCache := Map clone
        self _updateCache := Map clone
        self _updateDeps(self)
        self rebuildChildren
        Builder with(self) build
        self struct build tmp remove
        lock unlock)

    _checkMissing := method(topParent,
        if (topParent missing isEmpty not, 
            Exception raise(
                MissingDependenciesError with(self struct manifest name))))

    _updateDeps := method(topParent,
        deps := self _unresolvedDeps(
            self struct manifest packs values,
            topParent,
            topParent _updateCache)
        if (deps isEmpty not,
        Logger log("[[cyan bold;Updating [[reset;dependencies of " ..
            "#{self struct manifest name}", 
            "output"))
        deps foreach(dep, dep update(topParent, self)))

    /*doc Package load(parentCtx)
    Loads the package and all of its dependencies.

    `parentCtx` is any object, which suppose to be the context of the package.
    The method will use global context if `parentCtx` is `nil`.

    The context will have slot `package`, which is the package loaded in this
    context.*/
    load := method(parentCtx, _cache, _topParent,
        _topParent = _topParent ifNilEval(self)
        _cache = _cache ifNilEval(Map clone)

        self _checkMissing(_topParent)

        ctx := self _initContext(parentCtx)

        isCached := self _loadCache(_cache, parentCtx, ctx)

        if (self recursive or isCached, return)

        # They did it for AddonLoader "to avoid loops when a addon file refs
        # another before it's loaded"
		Importer addSearchPath(self struct io path) 

        self _loadDeps(ctx, _cache, _topParent)

        self _loadDynLib(ctx)

        self _loadIoFiles(ctx)

		Importer removeSearchPath(self struct io path))

    _initContext := method(parentCtx,
        ctx := Object clone
        ctx package := self
        parentCtx = parentCtx ifNilEval(Lobby)
        parentCtx setSlot(self struct manifest name, ctx)
        ctx type = self struct manifest name
        ctx)

    _loadCache := method(cache, parentCtx, ctx,
        cacheKey := self _loadCacheKey(ctx package)
        result := cache hasKey(cacheKey)

        if (result, 
            parentCtx setSlot(
                ctx package struct manifest name, 
                cache at(cacheKey)),
            cache atPut(cacheKey, ctx))

        result)

    _loadCacheKey := method(package, 
        package struct manifest name .. 
        "@" .. 
        package struct manifest version asSeq)

    _loadDeps := method(parentCtx, cache, topParent,
        self children foreach(name, dep,
            dep load(parentCtx, cache, topParent)))

    _loadDynLib := method(ctx,
        if (self struct hasNativeCode not, return)
        self _checkCompiled
        dll := DynLib clone setPath(self struct dllPath)
        dll open call("Io" .. self struct manifest name .. "Init", ctx))

    _checkCompiled := method(
        if (self struct hasNativeCode and \
            File with(self struct dllPath) exists not,
            Exception raise(NotCompiledError with(self struct manifest name))))

    _loadIoFiles := method(ctx,
		self struct io files foreach(file, ctx doFile(file path)))

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

    //doc Package MissingDependenciesError
    MissingDependenciesError := Eerie Error clone setErrorMsg(
        "The package \"#{call evalArgAt(0)}\" has missing dependencies. " .. 
        "Please, reinstall the package.")

    //doc Package FailedRunHookError
    FailedRunHookError := Eerie Error clone setErrorMsg(
        "Failed run hook \"#{call evalArgAt(0)}\":\n#{call evalArgAt(1)}")

    //doc Package NotCompiledError
    NotCompiledError := Eerie Error clone setErrorMsg(
        "The package '#{call evalArgAt(0)}' is not compiled.")

)
