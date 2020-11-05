Importer addSearchPath("io/Eerie/Builder")

InstallerTest := UnitTest clone do (
    
    package := Package with(Directory with("tests/_addons/AFakeAddon"))

    setUp := method(
        self package addonsDir remove
        self package destBinDir remove)

    tearDown := method(
        self package addonsDir remove
        self package destBinDir remove)

    testPackageSet := method(
        installer := Installer clone

        e := try (installer _checkPackageSet)
        assertEquals(e error type, Installer PackageNotSetError type))

    testNoDep := method(
        dependency := Package with(Directory with("tests/_addons/DFakeAddon"))
        installer := Installer with(self package)

        e := try (installer install(dependency))
        assertEquals(e error type, Package NoDependencyError type))

    testInstall := method(
        # this package has binaries, so we check binaries installation too
        dependency := Package with(Directory with("tests/_addons/BFakeAddon"))
        installer := Installer with(self package)

        installer install(dependency)

        assertFalse(self package packageNamed(dependency name) isNil)

        assertEquals(
            self package packageNamed(dependency name) name, dependency name)

        # check binaries installation
        assertTrue(self package destBinDir exists)
        assertTrue(self package destBinDir files size > 0)

        if (Eerie isWindows not,
            self package destBinDir files foreach(file,
                # it looks like links don't exist as a file in Io: neither
                # `File exists` nor `File isLink` don't work, so:
                assertTrue(
                    self package destBinDir files map(name) contains(
                        file name))))

        # installing it again should raise an exception
        e := try (installer install(dependency))
        assertEquals(e error type, Installer DirectoryExistsError type))

    testInstallBinaries := method(
        # the rest of the test is inside testInstall

        installer := Installer with(self package)
        # a package without binaries
        dependency := Package with(Directory with("tests/_addons/CFakeAddon"))

        # should return `false`, because the package has no binaries
        assertFalse(installer _installBinaries(dependency)))

)
