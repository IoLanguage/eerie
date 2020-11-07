TransactionLockTest := UnitTest clone do(
    
    lock ::= TransactionLock clone

    setUp := method(
        self lock file = File with("tests/transaction_lock"))

    tearDown := method(
        if(self lock file exists, self lock file close remove))

    testIsProcessRunning := method(
        assertTrue(self lock _isProcessRunning(System thisProcessPid))       
        # hope there's no process with such ID, but theoretically this test may
        # fail if there's such a process
        assertFalse(self lock _isProcessRunning("1000000000")))

    testAbandoned := method(
        # this test may fail if for some very rare circumstances there's a
        # process with this id
        self lock file setContents("1000000000")
        self lock _checkAbandoned
        assertFalse(self lock file exists))

)
