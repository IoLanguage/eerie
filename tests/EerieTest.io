EerieTest := UnitTest clone do (

    testSetGlobal := method(
        Eerie 
        assertFalse(Eerie isGlobal)

        Eerie setIsGlobal(true)
        assertTrue(Eerie isGlobal))

    testExceptionWithoutEeridir := method(
        backup := System getEnvironmentVariable("EERIEDIR")
        System setEnvironmentVariable("EERIEDIR", "")
        e := try (Eerie init)
        System setEnvironmentVariable("EERIEDIR", backup)
        assertEquals(e error type, Eerie EerieDirNotSetError type))

)
