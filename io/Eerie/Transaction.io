//metadoc Transaction category API
//metadoc Transaction description

Transaction := Object clone do(
    items := List clone
    depsCheckedFor  := List clone

    init := method(
        self items = List clone
        self depsCheckedFor = List clone
        self acquireLock
    )

    /*doc Transaction lockFile A file with current Eerie process ID. Eerie
    checks for existence of this file to make it sure that only one instance of 
    Eerie is ranning.*/
    lockFile := File with(Eerie globalEerieDir .. "/.transaction_lock")

    //doc Transaction acquireLock Creates transaction lock.
    acquireLock := method(
        pid := if(lockFile exists, lockFile openForReading contents, nil)
        (pid == System thisProcessPid asString) ifTrue(
            Eerie log("Trying to acquire lock but its already present.", "debug")
            return(true)
        )

        _checkAbandonedLock

        while(self lockFile exists,
            Eerie log("[#{Date now}] Process #{pid} has lock. Waiting for process to finish...", "error")
            System sleep(5)
        )

        self lockFile close \
            open setContents(System thisProcessPid asString) close
        true
    )
  
    # remove the lock if it exists, but the process isn't running
    _checkAbandonedLock := method(
        if(self lockFile exists not, return)
        pid := self lockFile contents
        if(_isProcessRunning(pid) not, self lockFile remove)
    )

    _isProcessRunning := method(pid,
        isWindows := (System platform containsAnyCaseSeq("windows") or(
            System platform containsAnyCaseSeq("mingw"))
        )

        cmd := if(isWindows,
            "TASKLIST /FI \"PID eq #{pid}\" 2>NUL | find \"#{pid}\" >NUL" \
            interpolate ,
            "ps -p #{pid} > /dev/null" interpolate
        )

        return System system(cmd) == 0
    )

    //doc Transaction releaseLock
    releaseLock := method(
        self lockFile exists ifFalse(return true)

        if(self lockFile openForReading contents == System thisProcessPid asString,
            self lockFile close remove
            true
        )
    )
      
    //doc Transaction hasLock
    hasLock := method(
        self lockFile exists ifFalse(return(false))
        self lockFile contents == System thisProcessPid asString
    )

    //doc Transaction run
    run := method(
        self items isEmpty ifTrue(
            return(self releaseLock)
        )

        self items = self items select(action,
            #Eerie log("Preparing #{action name} for #{action pkg uri}...")
            action prepare ifTrue(self resolveDeps(action pkg))
        )

        self items reverse foreach(action,
            Eerie log("#{action asVerb} #{action pkg name}...")
            action execute
        )

        self releaseLock
    )

    //doc Transaction actsUpon(package)
    actsUpon := method(package,
        uri := package uri
        self items detect(act, act second uri == uri) != nil
    )

    //doc Transaction addAction(action)
    addAction := method(action,
        self items contains(action) ifFalse(
            Eerie log("#{action name} #{action pkg name}", "transaction")
            self items append(action)
        )
        self
    )

    install := method(package,
        self addAction(Eerie TransactionAction named("Install") with(package))
    )

    update := method(package,
        self addAction(Eerie TransactionAction named("Update") with(package))
    )

    remove := method(package,
        self addAction(Eerie TransactionAction named("Remove") with(package)))

    resolveDeps := method(package,
        Eerie log("Resolving dependencies for #{package name}")
        deps := package info at("dependencies")
        if(deps == nil or deps ?keys ?isEmpty,
            return(true)
        )

        toInstall := list()
        deps at("packages") ?foreach(uri,
            self depsCheckedFor contains(uri) ifTrue(continue)
            if(Eerie packages detect(pkg, pkg uri == uri) isNil,
                toInstall appendIfAbsent(Eerie Package fromUri(uri))
            )
        )

        deps at("protos") ?foreach(protoName,
            AddonLoader hasAddonNamed(protoName) ifFalse(
                Eerie MissingProtoException raise(list(package name, protoName))
            )
        )

        self depsCheckedFor append(package uri)
        Eerie log("Missing pkgs: #{toInstall map(name)}", "debug")
        toInstall foreach(pkg, 
            Eerie Transaction clone install(pkg) run
        )
        true
    )

)


