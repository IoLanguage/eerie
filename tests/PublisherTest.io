PublisherTest := UnitTest clone do (

    testPackageSet := method(
        publisher := Publisher with(nil)
        e := try (publisher _checkPackageSet)
        assertEquals(e error type, Publisher PackageNotSetError type))

    testCheckVersion := method(
        package := Package with("tests/_packs/BFakePack")
        publisher := Publisher with(package)

        # should pass validation as the previous version is nil
        publisher _checkVersionNewer

        package versions := list(SemVer fromSeq("0.1.1"))
        e := try (publisher _checkVersionNewer)
        assertEquals(e error type, Publisher VersionIsOlderError type)

        # we have AFakePack with the same version in our test database
        package = Package with("tests/_packs/AFakePack")
        publisher setPackage(package)
        e := try (publisher _checkVersionNewer)
        assertEquals(e error type, Publisher VersionIsOlderError type)

        package manifest version = SemVer fromSeq("0.1.1")
        # should pass now
        publisher _checkVersionNewer)

    testHasGitChanges := method(
        # this test may fail if tests/_tmp/CFakePackUpdate have uncommitted 
        # changes
        package := Package with("tests/_tmp/CFakePackUpdate")
        publisher := Publisher with(package)

        change := File with("tests/_tmp/CFakePackUpdate/deleteme") 
        change create remove

        publisher _checkHasGitChanges

        change create

        e := try (publisher _checkHasGitChanges)
        assertEquals(e error type, Publisher HasGitChangesError type)
        change remove)

    testGitTagExists := method(
        package := Package with("tests/_tmp/CFakePackUpdate")
        publisher := Publisher with(package)
        package manifest version := SemVer fromSeq("0.1.0")

        e := try (publisher _checkGitTagExists)
        assertEquals(e error type, Publisher GitTagExistsError type)

        package manifest version := SemVer fromSeq("10.0.0")
        publisher _checkGitTagExists)

    testPromptPush := method(
        # TODO
        # don't know how to test it
        # kept it here for manual testing at least
        # package := Package with("tests/_packs/AFakePack")
        # publisher := Publisher with(package)
        # publisher shouldPush println
        # publisher _promptPush
        # publisher shouldPush println
    )

)
