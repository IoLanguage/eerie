PublisherTest := UnitTest clone do (

    testPackageSet := method(
        publisher := Publisher with(nil)
        e := try (publisher _checkPackageSet)
        assertEquals(e error type, Publisher PackageNotSetError type))

    testCheckVersion := method(
        package := Package with(Directory with("tests/_addons/BFakeAddon"))
        publisher := Publisher with(package)

        # should pass validation as the previous version is nil
        publisher _checkVersion

        package versions := list(SemVer fromSeq("0.1.1"))
        e := try (publisher _checkVersion)
        assertEquals(e error type, Publisher VersionIsOlderError type)

        # we have AFakeAddon with the same version in our test database
        package = Package with(Directory with("tests/_addons/AFakeAddon"))
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
        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        publisher := Publisher with(package)
        
        e := try (publisher _checkReadme)
        assertEquals(e error type, Publisher ReadmeError type)

        # package with readme field
        package = Package with(Directory with("tests/_addons/DFakeAddon"))
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
        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        publisher := Publisher with(package)
        
        e := try (publisher _checkLicense)
        assertEquals(e error type, Publisher LicenseError type)

        # package with readme field
        package = Package with(Directory with("tests/_addons/DFakeAddon"))
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
        package := Package with(Directory with("tests/_addons/BFakeAddon"))
        publisher := Publisher with(package)

        e := try (publisher _checkDescription)
        assertEquals(e error type, Publisher NoDescriptionError type)

        package = Package with(Directory with("tests/_addons/AFakeAddon"))
        publisher setPackage(package)
        publisher _checkDescription)

)
