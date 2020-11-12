Importer addSearchPath("io/Eerie/Package")


StructureTest := UnitTest clone do (

    testIsPackage := method(
        root := Directory with("tests/_fpacks/NotPack")
        assertFalse(Structure isPackage(root)))

    testHasNativeCode := method(
        aStruct := Structure with("tests/_packs/AFakePack")
        assertFalse(aStruct hasNativeCode)

        cStruct := Structure with("tests/_packs/CFakePack")
        assertTrue(cStruct hasNativeCode))

    testHasBinaries := method(
        aStruct := Structure with("tests/_packs/AFakePack")
        assertFalse(aStruct hasBinaries)

        bStruct := Structure with("tests/_packs/BFakePack")
        assertTrue(bStruct hasBinaries))

)


