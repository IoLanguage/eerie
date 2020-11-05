PublisherTest := UnitTest clone do (

    testPackageSet := method(
        publisher := Publisher with(nil)
        e := try (publisher _checkPackageSet)
        assertEquals(e error type, Publisher PackageNotSetError type))

    testCheckVersion := method(
        package := Package with("tests/_addons/BFakeAddon")
        publisher := Publisher with(package)

        # should pass validation as the previous version is nil
        publisher _checkVersion

        package versions := list(SemVer fromSeq("0.1.1"))
        e := try (publisher _checkVersion)
        assertEquals(e error type, Publisher VersionIsOlderError type)

        # we have AFakeAddon with the same version in our test database
        package = Package with("tests/_addons/AFakeAddon")
        publisher setPackage(package)
        e := try (publisher _checkVersion)
        assertEquals(e error type, Publisher VersionIsOlderError type)

        package version = SemVer fromSeq("0.1.1")
        # should pass now
        publisher _checkVersion

        # shouldn't pass because of the shortened version
        package version = SemVer fromSeq("0.1")
        e := try (publisher _checkVersion)
        assertEquals(e error type, Publisher VersionIsShortened type))

    testCheckReadme := method(
        package := Package with("tests/_addons/AFakeAddon")
        publisher := Publisher with(package)
        
        e := try (publisher _checkReadme)
        assertEquals(e error type, Publisher ReadmeError type)

        # package with readme field
        package = Package with("tests/_addons/DFakeAddon")
        readme := package dir fileNamed("README.md") create remove
        publisher setPackage(package)

        # it doesn't exist
        e := try (publisher _checkReadme)
        assertEquals(e error type, Publisher ReadmeError type)

        # make it exists, but empty
        readme create
        e := try (publisher _checkReadme)
        assertEquals(e error type, Publisher ReadmeError type)
        
        readme setContents("# " .. package name)
        publisher _checkReadme
        readme remove)

    testCheckLicense := method(
        package := Package with("tests/_addons/AFakeAddon")
        publisher := Publisher with(package)
        
        e := try (publisher _checkLicense)
        assertEquals(e error type, Publisher LicenseError type)

        # package with readme field
        package = Package with("tests/_addons/DFakeAddon")
        license := package dir fileNamed("LICENSE") create remove
        publisher setPackage(package)

        # it doesn't exist
        e := try (publisher _checkLicense)
        assertEquals(e error type, Publisher LicenseError type)

        # make it exists, but empty
        license create
        e := try (publisher _checkLicense)
        assertEquals(e error type, Publisher LicenseError type)
        
        license setContents(package name)
        publisher _checkLicense
        license remove)

    testDescriptionCheck := method(
        # package with empty description
        package := Package with("tests/_addons/BFakeAddon")
        publisher := Publisher with(package)

        e := try (publisher _checkDescription)
        assertEquals(e error type, Publisher NoDescriptionError type)

        package = Package with("tests/_addons/AFakeAddon")
        publisher setPackage(package)
        publisher _checkDescription)

    testHasGitChanges := method(
        # this test may fail if tests/_tmp/CFakeAddonUpdate have uncommitted 
        # changes
        package := Package with("tests/_tmp/CFakeAddonUpdate")
        publisher := Publisher with(package)

        change := File with("tests/_tmp/CFakeAddonUpdate/deleteme") 
        change create remove

        publisher _checkHasGitChanges

        change create

        e := try (publisher _checkHasGitChanges)
        assertEquals(e error type, Publisher HasGitChangesError type)
        change remove)

    testGitTagExists := method(
        package := Package with("tests/_tmp/CFakeAddonUpdate")
        publisher := Publisher with(package)
        package version := SemVer fromSeq("0.1.0")

        e := try (publisher _checkGitTagExists)
        assertEquals(e error type, Publisher GitTagExistsError type)

        package version := SemVer fromSeq("10.0.0")
        publisher _checkGitTagExists)

    testPromptPush := method(
        # TODO
        # don't know how to test it
        # kept it here for manual testing at least
        # package := Package with("tests/_addons/AFakeAddon")
        # publisher := Publisher with(package)
        # publisher shouldPush println
        # publisher _promptPush
        # publisher shouldPush println
    )

)
