//metadoc Eerie category API
//metadoc Eerie author Josip Lisec, Ales Tsurko
/*metadoc Eerie description 
This proto is a singleton. It's mainly for keeping `isGlobal` state and logging,
but it also contains some helpful functions.*/

Eerie := Object clone do (

    //doc Eerie isGlobal Whether the global environment in use. Default `false`.
    //doc Eerie setIsGlobal
    isGlobal ::= false
    
    //doc Eerie database Get instance of `Database` Eerie uses.
    database := nil

    init := method(
        # call this to check whether EERIEDIR set
        self root
        self database := Database clone
        if (self database needsUpdate, self _warnDbUpdate))

    _warnDbUpdate := method(
        Logger log("❕ [[yellow;The database is outdated" asUTF8, "output"))

    //doc Eerie root Returns value of EERIEDIR environment variable.
    root := method(
        path := System getEnvironmentVariable("EERIEDIR") \
            ?stringByExpandingTilde
        if(path isNil or path isEmpty,
            Exception raise(EerieDirNotSetError with("")))
        path)

    //doc Eerie dbDir Get `Directory` of database.
    dbDir := method(Directory with(self root .. "/db/db"))

    //doc Eerie platform Get the platform name (`Sequence`) as lowercase.
    platform := System platform split at(0) asLowercase

    //doc Eerie ddlExt Get dynamic library extension for the current platform.
    dllExt := method(
        if (Eerie isWindows) then (
            return "dll"
        ) elseif (Eerie platform == "darwin") then (
            return "dylib"
        ) else (
            return "so"))

    /*doc Eerie isWindows Returns `true` if the OS on which Eerie is running is
    Windows (including mingw define), `false` otherwise.*/
    isWindows := method(System platform containsAnyCaseSeq("windows") or(
        System platform containsAnyCaseSeq("mingw")))

    //doc Eerie ioHeadersPath Returns path (`Sequence`) to io headers.
    ioHeadersPath := method(Eerie root .. "/ioheaders")

    /*doc Eerie sh(cmd[, silent=false, path=cwd])
    Executes system command. Raises exception with `Eerie SystemCommandError` on
    failure. Will not print any output if `silent` is `true`.

    Returns the object returned by `System runCommand`.*/
    sh := method(cmd, silent, path,
        if (silent not, Logger log(cmd, "console"))
        
        prevDir := nil
        if(path != nil and path != ".",
            prevDir = Directory currentWorkingDirectory
            Directory setCurrentWorkingDirectory(path))

        cmdOut := System runCommand(cmd)
        stdOut := cmdOut stdout
        stdErr := cmdOut stderr

        Eerie _cleanRunCommand

        prevDir isNil ifFalse(Directory setCurrentWorkingDirectory(prevDir))
        
        if(cmdOut exitStatus != 0,
            Exception raise(
                SystemCommandError with(cmd, cmdOut exitStatus, stdErr)))

        cmdOut)


    # remove *-stdout and *-stderr files, which are kept in result of
    # System runCommand call
    _cleanRunCommand := method(
        Directory clone files select(file, 
            file name endsWithSeq("-stdout") or \
                file name endsWithSeq("-stderr")) \
                    foreach(remove))

)

//doc Eerie Error Eerie modules subclass this error for their error types.
Eerie Error := Error clone do (
    errorMsg ::= nil

    with := method(msg,
        super(with(self errorMsg interpolate)))
)

Eerie do (
    //doc Eerie MissingPackageError
    MissingPackageError := Error clone setErrorMsg(
        "Package '#{call evalArgAt(0)}' is missing.")

    //doc Eerie SystemCommandError
    SystemCommandError := Error clone setErrorMsg(
        "Command '#{call evalArgAt(0)}' exited with status code " .. 
        "#{call evalArgAt(1)}:\n#{call evalArgAt(2)}")

    //doc Eerie EerieDirNotSetError
    EerieDirNotSetError := Error clone setErrorMsg(
        "Environment variable EERIEDIR did not set.")
)

Eerie clone = Eerie do (

    //doc Eerie Package [Package](package.html)
    doRelativeFile("Eerie/Package.io")
    
    //doc Eerie Downloader [Downloader](downloader.html)
    doRelativeFile("Eerie/Downloader.io")
    
    //doc Eerie Installer [Installer](installer.html)
    doRelativeFile("Eerie/Installer.io")
    
    //doc Eerie Transaction [Transaction](transaction.html)
    doRelativeFile("Eerie/Transaction.io")
    
    //doc Eerie Action [Action](action.html)
    doRelativeFile("Eerie/Action.io")

    init
)

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
