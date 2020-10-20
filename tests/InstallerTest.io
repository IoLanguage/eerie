Importer addSearchPath("io/")
Importer addSearchPath("io/Eerie/")
Importer addSearchPath("io/Eerie/Builder")

InstallerTest := UnitTest clone do (
    package := Package with(Directory with("tests/_addons/AFakeAddon"))

    setUp := method(
        self package addonsDir remove
        self package destBinDir remove)

    tearDown := method(
        self package addonsDir remove
        self package destBinDir remove)

    testValidation := method(
        installer := Installer clone

        e := try (installer _checkPackageSet)
        assertEquals(e error type, Installer PackageNotSetError type))

    testInstall := method(
        # this package has binaries, so we check binaries installation too
        dependency := Package with(Directory with("tests/_addons/BFakeAddon"))
        installer := Installer with(self package)

        installer install(dependency)

        # validate that what we've installed is a package
        Package with(
            Directory with(self package addonsDir path .. "/BFakeAddon"))


        # check binaries installation
        assertTrue(self package destBinDir exists)
        assertTrue(self package destBinDir files size > 0)

        if (Eerie isWindows not,
            self package destBinDir files foreach(file,
                # it looks like links don't exist as a file in Io: neither
                # `File exists` nor `File isLink` don't work, so:
                assertTrue(
                    self package destBinDir files map(
                        name) contains(file name))))

        # installing it again should raise an exception
        e := try (installer install(dependency))
        assertEquals(e error type, Installer DirectoryExistsError type))

    testBuild := method(
        dependency := Package with(Directory with("tests/_addons/CFakeAddon"))
        initf := dependency sourceDir fileNamed("IoCFakeAddonInit.c")
        buildDir := dependency buildDir

        if (initf exists, initf remove)
        if (buildDir exists, buildDir remove)

        installer := Installer with(self package)

        installer build(dependency)

        assertTrue(buildDir exists)
        assertTrue(initf exists)

        buildDir remove
        initf remove)

    testInstallBinaries := method(
        # the rest of the test is inside testInstall

        installer := Installer with(self package)
        # a package without binaries
        dependency := Package with(Directory with("tests/_addons/CFakeAddon"))

        # should return `false`, because the package has no binaries
        assertFalse(installer _installBinaries(dependency)))

)
