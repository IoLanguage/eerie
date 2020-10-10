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

    testAddonsDir := method(
        expected := Eerie root .. "/_addons"
        assertEquals(Eerie addonsDir path, expected))

    testGeneratePackagePath := method(
        packageName := "FakePackageName"
        expected := Eerie addonsDir path .. "/#{packageName}" interpolate
        assertEquals(Eerie generatePackagePath(packageName), expected))

    testReloadPackagesList := method(
        Eerie
        Eerie setIsGlobal(true)
        expected := list("AFakeAddon", "BFakeAddon", "CFakeAddon")
        names := Eerie installedPackages map(name) sort
        assertEquals(expected, names))

    testExceptionWithoutEeridir := method(
        System setEnvironmentVariable("EERIEDIR", "")
        assertRaisesException(Eerie init))
)
