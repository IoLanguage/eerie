//metadoc Eerie category API
//metadoc Eerie author Josip Lisec
//metadoc Eerie description Eerie is the package manager for Io.
SystemCommand

System userInterruptHandler := method(
    Eerie log("Reverting addons.json before interrupt.")
    Eerie revertAddonsJson
    Eerie Transaction releaseLock)

Eerie := Object clone do(
    //doc Eerie tmpDir Get path to temp directory.
    globalEerieDir := System getEnvironmentVariable("EERIEDIR")
    tmpDir ::= globalEerieDir .. "/_tmp"
    addonsJson :=  nil
    addonsMap ::= nil
    addonsJsonBackup ::= nil
    /*doc Eerie root Current working directory or value of `EERIEDIR` system's 
    environment variable if `isGlobal` is `true`.*/
    root := method(if (isGlobal, globalEerieDir, "."))
    //doc Eerie addonsDir Path to directory where addons are installed.
    addonsDir := method(Directory with("${self root}/_addons" interpolate))
    //doc Eerie isGlobal Whether the global environment in use.
    isGlobal := method(self _isGlobal)
    _isGlobal := false

    init := method(
        envvar := globalEerieDir
        if(envvar isNil or envvar == "", 
            Exception raise("Error: EERIEDIR is not set")))

    //doc Eerie setIsGlobal Set whether the global environment in use. 
    setIsGlobal := method(value, 
        self _isGlobal = value
        self initConfig)

    initConfig := method(
        self addonsJson ?close
        self addonsJson := File with((self root) .. "/addons.json") 
        if (self addonsJson exists not, self _generateAddonsJson)
        self addonsJson openForUpdating
        self setConfig(self addonsJson contents parseJson)
        self setConfigBackup(self addonsJson contents)
        self)

    _generateAddonsJson := method(
        # TODO
    )

    /*doc Eerie sh(cmd[, logFailure=true, dir=cwd])
    Executes system command. If `logFailure` is `true` and command exists with
    non-zero value, the application will abort.
    */
    sh := method(cmd, logFailure, dir,
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
        
        if(cmdOut exitStatus != 0 and logFailure == true) \
        then (
            self log("Last command exited with the following error:", "error")
            self log(stdOut, "error")
            self log(stdErr, "error")
            System exit(cmdOut exitStatus)
        ) else (
            return cmdOut exitStatus))

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
        ((self _logMods at(mode)) .. str) interpolate(call sender) println)

    /*doc Eerie updateAddonsJson(key, value) Updates addons.json with given key
    and value.*/
    updateAddonsJson := method(key, value,
        self addonsMap atPut(key, value)
        self saveAddonsJson)

    //doc Eerie saveAddonsJson
    saveAddonsJson := method(
        self addonsJson close remove openForUpdating write(self addonsMap \
            asJson)
        self)

    /*doc Eerie revertAddonsJson Reverts addons.json to the state it was in
    before executing this script.*/
    revertAddonsJson := method(
        self addonsJson close remove openForUpdating write(
            self addonsJsonBackup)
        self setConfig(self addonsJsonBackup parseJson))

    /*doc Eerie generatePackagePath Return path for addon with the given name
    independently of its existence.*/
    generatePackagePath := method(name,
        self root .. "/_addons/#{name}" interpolate)

    /*doc Eerie packageNamed(name) Returns package with provided name if it 
    exists, `nil` otherwise.*/
    packageNamed := method(pkgName,
        self packages detect(pkg, pkg name == pkgName))

    /*doc Eerie appendPackage(package) Saves package's configuration into
    addons.json.*/
    appendPackage := method(package,
        self addonsMap at("packages") appendIfAbsent(package config)
        self packages appendIfAbsent(package)
        self saveAddonsJson)

    //doc Eerie removePackage(package) Removes the given package.
    removePackage := method(package,
        self addonsMap at("packages") remove(package config)
        self packages remove(package)
        self saveAddonsJson)

    //doc Eerie updatePackage(package)
    updatePackage := method(package,
        self addonsMap at("packages") detect(name == package name) isNil ifTrue(
            msg := "Tried to update package which is not yet installed."
            msg = msg .. " (#{self name}/#{package name})"
            Eerie log(msg, "debug")
            return false)

        self addonsMap at("packages") removeAt(package name) atPut(
            package name, package config)
        self packages remove(old) append(package)
        self saveAddonsJson)

    //doc Eerie packages Returns list of installed packages .
    packages := method(
        self addonsMap at("packages") map(pkgConfig,
            (pkgConfig type == "Map") ifFalse(pkgConfig = pkgConfig parseJson)
            Eerie Package withConfig(pkgConfig)))
)

Eerie clone = Eerie do(
    //doc Eerie Exception [Exception](exception.html)
    doRelativeFile("Eerie/Exception.io")
    //doc Eerie Package [Package](package.html)
    doRelativeFile("Eerie/Package.io")
    //doc Eerie PackageDownloader [PackageDownloader](packagedownloader.html)
    doRelativeFile("Eerie/PackageDownloader.io")
    //doc Eerie PackageInstaller [PackageInstaller](packageinstaller.html)
    doRelativeFile("Eerie/PackageInstaller.io")
    //doc Eerie Transaction [Transaction](transaction.html)
    doRelativeFile("Eerie/Transaction.io")
    //doc Eerie TransactionAction [TransactionAction](transactionaction.html)
    doRelativeFile("Eerie/TransactionAction.io")

    init
)
