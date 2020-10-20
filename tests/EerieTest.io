Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

EerieTest := UnitTest clone do (

    setUp := method(
        # this way we set global addons directory
        System setEnvironmentVariable("EERIEDIR", 
            Directory currentWorkingDirectory .. "/tests"))

    testSetGlobal := method(
        Eerie 
        assertFalse(Eerie isGlobal)

        Eerie setIsGlobal(true)
        assertTrue(Eerie isGlobal))

    testExceptionWithoutEeridir := method(
        System setEnvironmentVariable("EERIEDIR", "")
        e := try (Eerie init)
        assertEquals(e error type, Eerie EerieDirNotSetError type))

)
