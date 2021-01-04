EerieTest := UnitTest clone do (

    testExceptionWithoutEeridir := method(
        backup := System getEnvironmentVariable("EERIEDIR")
        System setEnvironmentVariable("EERIEDIR", "")
        e := try (Eerie init)
        System setEnvironmentVariable("EERIEDIR", backup)
        assertEquals(e error type, Eerie EerieDirNotSetError type))

    testUpgrade := method(
        assertEquals(
            "#{Eerie root}/_build/_tmp/upgrade" interpolate, 
            Eerie _downloadDir path)
    )

)
