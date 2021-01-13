InitFileGeneratorTest := UnitTest clone do (

    testGenerate := method(
        package := Package with("tests/_packs/CFakePack")
        generator := Builder InitFileGenerator with(package)
        generator generate
        
        result := package struct source fileNamed("IoCFakePackInit.c") 
        expected := if (Eerie isWindows, 
            knownBug("expected file on windows doesn't exist")
            package struct root directoryNamed("tests") \
                fileNamed("ExpectedInitWin.c"),
            package struct root directoryNamed("tests") \
                fileNamed("ExpectedInitUnix.c"))

        assertEquals(result contents, expected contents)

        result remove)

)
