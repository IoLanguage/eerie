//metadoc Eerie category API
//metadoc Eerie author Josip Lisec, Ales Tsurko
/*metadoc Eerie description 
This proto is a singleton.*/

System do (

    /*doc System sh(cmd[, silent=false, path=cwd])
    Executes system command. Raises exception with `System SystemCommandError`
    on failure. Will not print any output if `silent` is `true`.

    Returns the object returned by `System runCommand`.

    **WARNING**: this method removes all files with "-stdout" and "-stderr"
    suffixes inside the directory in which the command is supposed to be run.*/
    sh := method(cmd, silent, path,
        cmd = cmd interpolate(call sender)
        if (silent not, Logger log(cmd, "console"))
        
        prevDir := nil
        if(path != nil and path != ".",
            prevDir = Directory currentWorkingDirectory
            Directory setCurrentWorkingDirectory(path))

        cmdOut := System runCommand(cmd)
        stdOut := cmdOut stdout
        stdErr := cmdOut stderr

        System _cleanRunCommand

        prevDir isNil ifFalse(Directory setCurrentWorkingDirectory(prevDir))
        
        if(cmdOut exitStatus != 0,
            Exception raise(
                SystemCommandError withArgs(cmd, cmdOut exitStatus, stdErr)))

        cmdOut)

    # remove *-stdout and *-stderr files, which are kept in result of
    # System runCommand call
    _cleanRunCommand := method(
        Directory clone files select(file, 
            file name endsWithSeq("-stdout") or \
                file name endsWithSeq("-stderr")) \
                    foreach(remove))

)

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

    upgrade := method(
        if (self _checkForUpdates isNil, return)
        dest := self _downloadDir createIfAbsent
        self _downloadUpdate(dest)
        self _prepareUpdate(dest)
        self _installUpdate(dest))

    _checkForUpdates := method(
        verStr := Database valueFor("Eerie", "version")
        version := SemVer fromSeq(verStr)
        if (Package global struct manifest version < version, version, nil))

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

    /*doc Eerie warnUpdateAvailable 
    Prints warning if a new version of Eerie is available.*/
    warnUpdateAvailable := method(
        if (version := self _checkForUpdates,
            Logger log(
                "Eerie v#{version asSeq} is available. Run 'eerie upgrade'.",
                "warning")))

)

# to prevent conflicts issues if there's another Eerie
Lobby prependProto(Eerie)

//metadoc Error category API
/*metadoc Error description Extended `Error` type used by Eerie.*/
Error := Error clone do (

    //doc Error setErrorMsg(Sequence)
    /*doc Error errorMsg 
    Error message template which is supposed to be used in pair with 
    `Error withArgs`.*/
    errorMsg ::= nil

    /*doc Error withArgs 
    An error with variable arguments. 

    This method is supposed to be used in pair with `Error setErrorMsg`.

    Example:

    ```Io
    # first you define your error type
    SystemCommandError := Eerie Error clone setErrorMsg(
        "Command '#{call evalArgAt(0)}' exited with status code " .. 
        "#{call evalArgAt(1)}:\n#{call evalArgAt(2)}")

    # then you can raise it with arguments
    Exception raise(SystemCommandError withArgs("foo", 1, "bar"))
    ```
    */
    withArgs := method(super(with(self errorMsg interpolate)))

)

Eerie do (

    //doc Eerie EerieDirNotSetError
    EerieDirNotSetError := Error clone setErrorMsg(
        "Environment variable EERIEDIR did not set.")

)

System do (

    //doc System SystemCommandError
    SystemCommandError := Error clone setErrorMsg(
        "Command '#{call evalArgAt(0)}' exited with status code " .. 
        "#{call evalArgAt(1)}:\n#{call evalArgAt(2)}")

)

Eerie clone = Eerie do (init)

/*doc Directory copyTo 
Copy content of a directory into destination directory path.*/
Directory copyTo := method(destination,
    destination createIfAbsent
    absoluteDest := Path absolute(destination path)

    # keep path to the current directory to return when we're done
    wd := Directory currentWorkingDirectory
    # change directory, to copy only what's inside the source
    Directory setCurrentWorkingDirectory(self path)


    Directory clone walk(item,
        newPath := absoluteDest .. "/" .. item path
        if (item type == File type) then (
            Directory with(newPath pathComponent) createIfAbsent 
            # `File copyToPath` has rights issues, `File setPath` too, so we
            # just create a new file here and copy the content of the source
            # into it
            File with(newPath) create setContents(item contents) close
        ) else (
            Directory createIfAbsent(newPath)))

    Directory setCurrentWorkingDirectory(wd))
