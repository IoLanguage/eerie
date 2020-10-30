Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

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
        assertEquals(e error type, Eerie EerieDirNotSetError type)
        System setEnvironmentVariable("EERIEDIR", backup))

)
