Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

InitFileGeneratorTest := UnitTest clone do (
    
    testGenerate := method(
        package := Package with(Directory with("tests/_addons/CFakeAddon"))
        generator := Builder InitFileGenerator with(package)
        generator generate
        
        result := package sourceDir fileNamed("IoCFakeAddonInit.c") 
        expected := if (Eerie isWindows, 
            knownBug("expected file on windows doesn't exist")
            package dir directoryNamed("tests") fileNamed("ExpectedInitWin.c"),
            package dir directoryNamed("tests") fileNamed("ExpectedInitUnix.c"))
        
        assertEquals(result contents, expected contents)

        result remove)
)
