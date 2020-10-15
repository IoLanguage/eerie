//metadoc Eerie category API
//metadoc Eerie author Josip Lisec, Ales Tsurko
//metadoc Eerie description Eerie is the Io package manager.
SystemCommand

System userInterruptHandler := method(
    Eerie Transaction releaseLock
    super(userInterruptHandler))

Eerie := Object clone do(
    //doc Eerie manifestName The name of the manifest file.
    manifestName := "eerie.json"
    /*doc Eerie root Current working directory or value of `EERIEDIR` system's 
    environment variable if `isGlobal` is `true`.*/
    root := method(if (self isGlobal, globalRoot, "."))
    //doc Eerie globalRoot Returns value of EERIEDIR environment variable.
    globalRoot := method(
        System getEnvironmentVariable("EERIEDIR"))
    //doc Eerie tmpDir Get temp `Directory`.
    tmpDir ::= Directory with(globalRoot .. "/_tmp")
    //doc Eerie addonsDir `Directory` where addons are installed.
    addonsDir := method(Directory with("#{self root}/_addons" interpolate))
    /*doc Eerie globalBinDirName The name of the directory where binaries from
    the packages will be installed globally. Default to `"_bin"`.*/
    globalBinDirName := "_bin"
    //doc Eerie isGlobal Whether the global environment in use.
    isGlobal := method(self _isGlobal)
    _isGlobal := false

    //doc Eerie setIsGlobal Set whether the global environment in use. 
    setIsGlobal := method(value, 
        self _isGlobal = value
        self _reloadPackagesList
        self)

    /*doc Eerie isWindows Returns `true` if the OS on which Eerie is running is
    Windows (including mingw define), `false` otherwise.*/
    isWindows := method(System platform containsAnyCaseSeq("windows") or(
        System platform containsAnyCaseSeq("mingw")))

    //doc Eerie installedPackages Returns list of installed packages .
    installedPackages := lazySlot(self _reloadPackagesList)

    _reloadPackagesList := method(
        self installedPackages = self addonsDir directories map(d,
            Package with(d)))

    init := method(
        if(globalRoot isNil or globalRoot isEmpty,
            Exception raise("Error: EERIEDIR is not set")))


    /*doc Eerie sh(cmd[, dir=cwd])
    Executes system command. Raises exception with `Eerie SystemCommandError` on
    failure.*/
    sh := method(cmd, dir,
        self log(cmd, "console")
        prevDir := nil
        dirPrefix := ""
        if(dir != nil and dir != ".",
            dirPrefix = "cd " .. dir .. " && "
            prevDir = Directory currentWorkingDirectory
            Directory setCurrentWorkingDirectory(dir))

        cmdOut := System runCommand(dirPrefix .. cmd)
        stdOut := cmdOut stdout
        stdErr := cmdOut stderr

        prevDir isNil ifFalse(Directory setCurrentWorkingDirectory(prevDir))

        # System runCommand leaves weird files behind
        SystemCommand rmFilesContaining("-stdout")
        SystemCommand rmFilesContaining("-stderr")
        
        if(cmdOut exitStatus != 0,
            Exception raise(
                SystemCommandError with(cmd, cmdOut exitStatus, stdErr)))

        cmdOut exitStatus)

    _logMods := Map with(
        "info",         " - ",
        "error",        " ! ",
        "console",      " > ",
        "debug",        " # ",
        "install",      " + ",
        "transaction",  "-> ",
        "output",       "")

    /*doc Eerie log(message, mode) Displays the message to the user. Mode can be
    `"info"`, `"error"`, `"console"`, `"debug"` or `"output"`.*/
    log := method(str, mode,
        mode ifNil(mode = "info")
        stream := if (mode == "error", File standardError, File standardOutput)
        msg := ((self _logMods at(mode)) .. str) interpolate(call sender)
        stream write(msg, "\n"))

    /*doc Eerie generatePackagePath Return path for addon with the given name
    independently of its existence.*/
    generatePackagePath := method(name,
        self addonsDir path .. "/#{name}" interpolate)

    /*doc Eerie packageNamed(name) Returns package with provided name if it 
    exists, `nil` otherwise.*/
    packageNamed := method(pkgName,
        self installedPackages detect(pkg, pkg name == pkgName))

    /*doc Eerie appendPackage(package) Append a package to the installedPackages
    list.*/
    appendPackage := method(package,
        self installedPackages appendIfAbsent(package))

    //doc Eerie removePackage(package) Removes the given package.
    removePackage := method(package, self installedPackages remove(package))

    //doc Eerie updatePackage(package)
    updatePackage := method(package,
        old := self installedPackages detect(p, p name == package name)
        old isNil ifTrue(
            msg := "Tried to update package which is not yet installed."
            msg = msg .. " (#{package name})"
            Eerie log(msg, "debug")
            return false)

        self installedPackages remove(old) append(package)
        true)

)

//doc Eerie Error Eerie modules subclass this error for their error types.
Eerie Error := Error clone do (
    errorMsg ::= nil

    with := method(msg,
        Eerie Transaction releaseLock
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
