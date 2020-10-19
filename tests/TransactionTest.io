Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

TransactionTest := UnitTest clone do(
    
    transaction ::= nil

    setUp := method(
        Transaction lockFile = File with("tests/transaction_lock")
        setTransaction(Transaction clone))

    tearDown := method(
        if(self transaction lockFile exists, 
            self transaction lockFile close remove))

    testIsProcessRunning := method(
        assertTrue(self transaction _isProcessRunning(System thisProcessPid))       
        # hope there's no process with such ID, but theoretically this test may
        # fail if there's such a process
        assertFalse(self transaction _isProcessRunning("1000000000")))

    testAbandonedLock := method(
        # this test may fail if for some very rare circumstances there's a
        # process with this id
        self transaction lockFile setContents("1000000000")
        self transaction _checkAbandonedLock
        assertFalse(self transaction lockFile exists))

)
