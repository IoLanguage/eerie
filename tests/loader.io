#!/usr/bin/env io

# this test should be run separately to prevent colliding contexts

System setEnvironmentVariable("EERIEDIR", Directory currentWorkingDirectory)
System setEnvironmentVariable("EERIE_LOG_FILTER", "debug")

LoaderTest := UnitTest clone do (

    doFile(Path with(Directory currentWorkingDirectory, "io", "Loader.io"))

    testLoad := method(

        ctx := Object clone

        Loader load(ctx)
        
        assertTrue(ctx hasSlot("Eerie"))

        assertTrue(ctx Eerie hasSlot("Eerie"))
        assertTrue(ctx Eerie hasSlot("Package"))
        assertTrue(ctx Eerie hasSlot("Rainbow"))
        assertTrue(ctx Eerie Rainbow hasSlot("Rainbow"))

        # the issue, which was introduced by doRelativeFile in Loader load
        assertFalse(ctx Eerie Rainbow hasSlot("SemVer"))
        assertFalse(ctx Eerie Rainbow hasSlot("Eerie"))
        assertFalse(ctx Eerie Rainbow hasSlot("Database"))
        assertFalse(ctx Eerie Rainbow hasSlot("Package")))

)

System exit(FileCollector run size)
