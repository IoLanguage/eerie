LoaderTest := UnitTest clone do (

    testLoad := method(
        ctx := Object clone

        Loader load(ctx)
        
        assertTrue(ctx hasSlot("Eerie"))

        assertEquals(
            Package global struct manifest version,
            ctx Eerie Package global struct manifest version)
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
