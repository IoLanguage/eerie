//metadoc Eerie category API
//metadoc Eerie author Josip Lisec, Ales Tsurko
/*metadoc Eerie description 
This proto is a singleton.*/

Eerie := Object clone do (

    //doc Eerie root Returns value of EERIEDIR environment variable.
    root := method(
        path := System getEnvironmentVariable("EERIEDIR") \
            ?stringByExpandingTilde
        if(path isNil or path isEmpty,
            Exception raise(EerieDirNotSetError withArgs("")))
        path)

    //doc Eerie repo Get Eerie repo URL.
    repo := "https://github.com/IoLanguage/eerie.git"
    
    //doc Eerie ioHeadersPath Returns path (`Sequence`) to io headers.
    ioHeadersPath := method(Path with(Eerie root, "ioheaders"))

    //doc Eerie ddlExt Get dynamic library extension for the current platform.
    dllExt := lazySlot(
        if (Eerie isWindows) then (
            return "dll"
        ) elseif (Eerie platform == "darwin") then (
            return "dylib"
        ) else (
            return "so"))

    /*doc Eerie isWindows Returns `true` if the OS on which Eerie is running is
    Windows (including mingw define), `false` otherwise.*/
    isWindows := lazySlot(
        System platform containsAnyCaseSeq("windows") or(
            System platform containsAnyCaseSeq("mingw")))

    //doc Eerie platform Get the platform name (`Sequence`) as lowercase.
    platform := System platform asLowercase

    init := method(
        # call this to check whether EERIEDIR set
        self root)

    /*doc Eerie warnUpdateAvailable 
    Prints warning if a new version of Eerie is available.*/
    warnUpdateAvailable := method(
        if (version := self _checkForUpdates,
            Logger log(
                "Eerie v#{version asSeq} is available. Run 'eerie upgrade'.",
                "warning")))

    _checkForUpdates := method(
        verStr := Database valueFor("Eerie", "version")
        if (verStr isNil, return)
        version := SemVer fromSeq(verStr)
        if (Package global struct manifest version < version, version, nil))

    upgrade := method(
        if (self _checkForUpdates isNil, return)
        dest := self _downloadDir createIfAbsent
        self _downloadUpdate(dest)
        self _prepareUpdate(dest)
        self _installUpdate(dest))

    _downloadDir := method(
        package := Package global
        package struct build tmp directoryNamed("upgrade"))

    _downloadUpdate := method(dest,
        cmd := "git clone #{Eerie repo} #{dest path}" interpolate
        System sh(cmd, true)
        System sh("git checkout master", true, dest path))

    _prepareUpdate := method(dest,
        manifest := self _prepareUpdateManifest(dest)
        manifest save
        backupDir := Package global struct root directoryNamed("_backup")
        self _backup(dir)
        self _outdatedItems foreach(remove))

    _prepareUpdateManifest := method(dest,
        manifestFile := dest fileNamed(Package Structure Manifest fileName)
        manifest := Package Structure Manifest with(manifestFile)
        Package global struct manifest packs foreach(dep, manifest addPack(dep))
        manifest)

    _backup := method(dir,
        dir create remove create
        backup := dir fileNamed(Package Structure Manifest fileName)
        Package global struct manifest file copyToPath(backup path))

    # notice, it doesn't include "_build" as it might keep update files
    # "_build" is supposed to be removed during the update installation
    _outdatedItems := method(
        keep := list("_backup", "_build", "db")
        Package global struct root localItems select(item,
            keep contains(item name) not))

    _installUpdate := method(updDir,
        updDir localItems foreach(item,
            path := Path with(Package global struct root path, item name)
            item moveTo(path))
        updDir remove
        Package global struct build root remove
        Package global install)

    /*doc Eerie dbg 
    When run in the debugger, pauses debugger after this message. Does nothing
    when run normally.*/
    dbg := method(
        if (Debugger hasSlot("_isDebugging") and Debugger _isDebugging, 
            Debugger _continue = false
            Coroutine currentCoroutine setMessageDebugging(true)))

)

Eerie do (

    //doc Eerie EerieDirNotSetError
    EerieDirNotSetError := Error clone setErrorMsg(
        "Environment variable EERIEDIR did not set.")

)

Eerie clone = Eerie do (init)
