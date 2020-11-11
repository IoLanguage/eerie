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
        updatee := Package with("tests/_tmp/CFakePackUpdate")
        target := Package with("tests/_packs/AFakePack")
        installer := Installer with(updatee, target struct root path)
        e := try (installer _checkSame(target))
        assertEquals(e error type, Installer DifferentPackageError type)

        target = Package with("tests/_packs/CFakePack")
        installer _checkSame(target))

    testBinSet := method(
        installer := Installer clone
        installer package = Package with("tests/_packs/BFakePack")

        assertTrue(installer package struct hasBinaries)

        e := try (installer _installBinaries)
        assertEquals(e error type, Installer BinDestNotSetError type))

    testInstall := method(
        parentPkg := Package with("tests/_packs/AFakePack")
        parentPkg struct packs remove
        parentPkg struct binDest remove

        # this package has binaries, so we check binaries installation too
        package := Package with("tests/_packs/BFakePack")
        destDir := parentPkg struct packs directoryNamed(package manifest name)
        installer := Installer with(
            package,
            destDir path,
            parentPkg struct binDest path)

        assertFalse(destDir exists)

        installer install

        assertTrue(destDir exists)

        # validate package
        Package with(destDir path)

        # check binaries installation
        assertTrue(parentPkg struct binDest exists)
        assertTrue(parentPkg struct binDest files size > 0)

        if (Eerie isWindows not,
            parentPkg struct binDest files foreach(file,
                # it looks like links don't exist as a file in Io: neither
                # `File exists` nor `File isLink` don't work, so:
                assertTrue(
                    parentPkg struct binDest files map(name) contains(file name))))

        # installing it again should raise an exception
        e := try (installer install)
        assertEquals(e error type, Installer DirectoryExistsError type)

        parentPkg struct packs remove
        parentPkg struct binDest remove)

    testUpdate := method(
        tmpDest := Directory with("tests/_tmp/Test")
        tmpDest create remove
        package := Package with("tests/_packs/CFakePack")
        installer := Installer with(package, tmpDest path)
        installer install

        installed := Package with(tmpDest path)
        assertEquals(installed manifest version, SemVer fromSeq("0.1.0"))

        updatee := Package with("tests/_tmp/CFakePackUpdate")
        installer setPackage(updatee)
        installer setDestination(installed struct root)

        newVersion := SemVer fromSeq("0.1.4")
        installer update(newVersion)

        installed := Package with(tmpDest path)
        assertEquals(installed manifest version, SemVer fromSeq("0.1.4"))

        installed remove)

)
