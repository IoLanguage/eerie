//metadoc Transaction category API
/*metadoc Transaction description
This proto is a collection of `Action`'s. You can view it as a receipt for
something that should be done with a package (i.e. installation, update etc.).
For example, `resolveDeps run` will download and install all dependencies of
`Transaction package`.

Also, `Transaction` saves you from accidentally running many instances of Eerie
commands for the same package at the same time using `.transaction_lock` file
for this.*/

Transaction := Object clone do(

    //doc Transaction package
    package ::= nil

    actions := list()
    
    /*doc Transaction lockFile
    A file containing current Eerie process ID. Eerie checks for existence of
    this file to make it sure that only one instance of Eerie is running per
    package.*/
    lockFile := method(self package packsDir fileNamed(".transaction_lock"))

    /*doc Transaction with(`Package`)
    Initializes `Transaction` with the given `Package`.*/
    with := method(pkg, Transaction clone setPackage(pkg))

    init := method(self acquireLock)

    /*doc Transaction acquireLock 
    Creates transaction lock.

    Raises `Transaction AnotherProcessRunningError` if a concurrent transaction
    is running.*/
    acquireLock := method(
        pid := if (self lockFile exists, 
            self lockFile contents,
            nil)

        if (pid == System thisProcessPid asString,
            Logger log(
                "Trying to acquire lock but its already present.", 
                "debug")
            return)

        self _checkAbandonedLock

        if (self lockFile exists, 
            Exception raise(AnotherProcessRunningError with(pid)))

        self lockFile setContents(System thisProcessPid asString))

    # remove the lock if it exists, but the process isn't running
    _checkAbandonedLock := method(
        if (self lockFile exists not, return)
        pid := self lockFile contents
        if (self _isProcessRunning(pid) not, self lockFile remove))

    _isProcessRunning := method(pid,
        cmd := if (Eerie isWindows,
            "TASKLIST /FI \"PID eq #{pid}\" 2>NUL | find \"#{pid}\" >NUL" \
            interpolate,
            "ps -p #{pid} > /dev/null" interpolate)

        return System system(cmd) == 0)

    /*doc Transaction releaseLock
    Remove transaction lock if it exists.*/
    releaseLock := method(
        if (self lockFile exists not, return)

        if(self lockFile contents == System thisProcessPid asString,
            self lockFile remove
            return))

    //doc Transaction hasLock Get boolean whether the transaction has lock.
    hasLock := method(
        if (self lockFile exists not, return false)
        self lockFile contents == System thisProcessPid asString)

    /*doc Transaction run
    Runs all actions.*/
    run := method(
        if (self actions isEmpty, return self releaseLock)

        if (Eerie database needsUpdate, Eerie database update)

        self actions foreach(action,
            self resolveDeps(action prepare) ?run
            action execute)

        self releaseLock
        self actions = list())

    /*doc Transaction resolveDeps(package)
    Add actions to resolve dependencies for the passed `package`.

    If the `package` argument is `nil`, `self package` is used.*/
    resolveDeps := method(package,
        if (package isNil, package = self package)

        if (package deps isEmpty, return)

        Logger log("🗂 [[brightBlue bold;Resolving [[reset;" ..
            "dependencies for [[bold;#{package name}")

        package deps foreach(dep, self installDep(dep) run)

        self)

    /*doc Transaction installDep(dependency)
    Add `Install` action with `Package Dependency`.*/
    installDep := method(dep,
        self _addAction(Action named("Install") with(self package, dep)))

    updateDeps := method(
        # TODO
    )

    updateDep := method(dep,
        self _addAction(Action named("Update") with(self package, dep)))

    _addAction := method(action,
        self actions contains(action) ifFalse(
            Logger log("#{action name} #{action dep name}", "transaction")
            self actions append(action))

        self)

)

# Error types
Transaction do (

    //doc Transaction ProcessLockedError
    AnotherProcessRunningError := Eerie Error clone setErrorMsg(
        "Another Eerie transaction with PID #{call evalArgAt(0)} " ..
        "is running.")

)
