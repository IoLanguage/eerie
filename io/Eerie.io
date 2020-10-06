//metadoc Eerie category API
//metadoc Eerie author Josip Lisec
//metadoc Eerie description Eerie is the package manager for Io.
SystemCommand

System userInterruptHandler := method(
    Eerie log("Reverting config before interrupt.")
    Eerie revertConfig
    Eerie Transaction releaseLock)

Eerie := Object clone do(
    //doc Eerie root Value of EERIEDIR system's environment variable.
    root ::= System getEnvironmentVariable("EERIEDIR")
    //doc Eerie tmpDir Get path to temp directory.
    tmpDir ::= root .. "/tmp"
    /*doc Eerie isGlobal Whether the global environment in use. Default to
    `false`.*/
    isGlobal ::= false
    configFile :=  nil
    config ::= nil
    configBackup ::= nil

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

    init := method(
        self configFile := File with((self root) .. "/config.json") 
        self configFile openForUpdating
        self setConfig(self configFile contents parseJson)
        self setConfigBackup(self configFile contents)
        self)

    //doc Eerie updateConfig(key, value) Updates config Map.
    updateConfig := method(key, value,
        self config atPut(key, value)
        self saveConfig)

    //doc Eerie saveConfig
    saveConfig := method(
        self configFile close remove openForUpdating write(self config asJson)
        self)

    /*doc Eerie revertConfig Reverts config to the state it was in before 
    executing this script.*/
    revertConfig := method(
        self configFile close remove openForUpdating write(self configBackup)
        self setConfig(self configBackup parseJson))
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
