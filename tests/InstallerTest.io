Importer addSearchPath("io/Eerie/Builder")

InstallerTest := UnitTest clone do (
    
    testPackageSet := method(
        installer := Installer clone

        e := try (installer _checkPackageSet)
        assertEquals(e error type, Installer PackageNotSetError type))

    testDestinationSet := method(
        installer := Installer clone

        e := try (installer _checkDestinationSet)
        assertEquals(e error type, Installer DestinationNotSetError type))

    testCheckSame := method(
        updatee := Package with("tests/_tmp/CFakeAddonUpdate")
        target := Package with("tests/_addons/AFakeAddon")
        installer := Installer with(updatee, target dir path)
        e := try (installer _checkSame(target))
        assertEquals(e error type, Installer DifferentPackageError type)

        target = Package with("tests/_addons/CFakeAddon")
        installer _checkSame(target))

    testBinSet := method(
        installer := Installer clone
        installer package = Package with("tests/_addons/BFakeAddon")

        assertTrue(installer package hasBinaries)

        e := try (installer _installBinaries)
        assertEquals(e error type, Installer BinDestNotSetError type))

    testInstall := method(
        parentPkg := Package with("tests/_addons/AFakeAddon")
        parentPkg addonsDir remove
        parentPkg destBinDir remove

        # this package has binaries, so we check binaries installation too
        package := Package with("tests/_addons/BFakeAddon")
        installer := Installer with(
            package,
            parentPkg addonDirFor(package) path,
            parentPkg destBinDir path)

        assertFalse(parentPkg addonDirFor(package) exists)

        installer install

        assertTrue(parentPkg addonDirFor(package) exists)

        # validate package
        Package with(parentPkg addonDirFor(package) path)

        # check binaries installation
        assertTrue(parentPkg destBinDir exists)
        assertTrue(parentPkg destBinDir files size > 0)

        if (Eerie isWindows not,
            parentPkg destBinDir files foreach(file,
                # it looks like links don't exist as a file in Io: neither
                # `File exists` nor `File isLink` don't work, so:
                assertTrue(
                    parentPkg destBinDir files map(name) contains(file name))))

        # installing it again should raise an exception
        e := try (installer install)
        assertEquals(e error type, Installer DirectoryExistsError type)

        parentPkg addonsDir remove
        parentPkg destBinDir remove)

    testUpdate := method(
        tmpDest := Directory with("tests/_tmp/Test")
        tmpDest create remove
        package := Package with("tests/_addons/CFakeAddon")
        installer := Installer with(package, tmpDest path)
        installer install

        installed := Package with(tmpDest path)
        assertEquals(installed version, SemVer fromSeq("0.1.0"))

        updatee := Package with("tests/_tmp/CFakeAddonUpdate")
        installer setPackage(updatee)
        installer setDestination(installed dir)

        newVersion := SemVer fromSeq("0.1.4")
        installer update(newVersion)

        installed := Package with(tmpDest path)
        assertEquals(installed version, SemVer fromSeq("0.1.4"))

        installed remove)

)
