Importer addSearchPath("io")
Importer addSearchPath("Eerie")

LoggerTest := UnitTest clone do (

    testCheckMode := method(
        e := try (Logger log("test", "foobar"))
        assertEquals(e error type, Logger UnknownModeError type))

    testCheckFilter := method(
        backup := Logger filter
        Logger setFilter("foobar")

        e := try (Logger log("test"))
        assertEquals(e error type, Logger UnknownFilterError type)

        Logger setFilter(backup))

)
