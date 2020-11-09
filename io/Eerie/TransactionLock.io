//metadoc TransactionLock category API
/*metadoc TransactionLock description
`TransactionLock` prevents you from running some commands (like install and
update, for example) in multiple processes for the same package.*/

TransactionLock := Object clone do(

    /*doc TransactionLock file
    A file containing current Eerie process ID.*/
    file := method(self package struct packs fileNamed(".transaction_lock"))

    //doc TransactionLock lock Lock the transaction.
    lock := method(
        pid := if (self file exists, 
            self file contents,
            nil)

        if (pid == System thisProcessPid asString,
            Logger log(
                "Trying to acquire lock but its already present.", 
                "debug")
            return)

        self _checkAdandoned

        if (self file exists, 
            Exception raise(AnotherProcessRunningError with(pid)))

        self file setContents(System thisProcessPid asString))

    # remove the lock if it exists, but the process isn't running
    _checkAbandoned := method(
        if (self file exists not, return)
        pid := self file contents
        if (self _isProcessRunning(pid) not, self file remove))

    _isProcessRunning := method(pid,
        cmd := if (Eerie isWindows,
            "TASKLIST /FI \"PID eq #{pid}\" 2>NUL | find \"#{pid}\" >NUL" \
            interpolate,
            "ps -p #{pid} > /dev/null" interpolate)

        return System system(cmd) == 0)

    /*doc TransactionLock unlock
    Unlock the transaction.*/
    unlock := method(if (self isLocked, self file remove))

    //doc TransactionLock isLocked Get boolean whether this lock is locked.
    isLocked := method(
        if (self file exists not, return false)
        self file contents == System thisProcessPid asString)

)

# Error types
TransactionLock do (

    //doc TransactionLock ProcessLockedError
    AnotherProcessRunningError := Eerie Error clone setErrorMsg(
        "Another Eerie transaction with PID #{call evalArgAt(0)} " ..
        "is running.")

)
