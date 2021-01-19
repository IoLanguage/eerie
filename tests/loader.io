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
        assertTrue(ctx Eerie Error hasSlot("withArgs"))
        assertTrue(ctx Eerie System hasSlot("sh"))

        # extensions shouldn't be available globally by default
        assertFalse(Error hasSlot("withArgs"))
        assertFalse(System hasSlot("sh"))

        # the issue, which was introduced by doRelativeFile in Loader load
        assertFalse(ctx Eerie Rainbow hasSlot("SemVer"))
        assertFalse(ctx Eerie Rainbow hasSlot("Eerie"))
        assertFalse(ctx Eerie Rainbow hasSlot("Database"))
        assertFalse(ctx Eerie Rainbow hasSlot("Package"))

        Loader unload(ctx)
        assertFalse(ctx hasSlot("Eerie")))

)

System exit(FileCollector run size)
