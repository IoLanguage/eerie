UpdaterTest := UnitTest clone do (

    package := Package with(Directory with("tests/_addons/AFakeAddon"))

    testCheckInstalled := method(
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(self package, update)

        e := try (updater _checkInstalled)
        assertEquals(e error type, Updater NotInstalledError type))

    testInitTargetVersion := method(
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(self package, update)

        assertTrue(updater _targetVersion isNil)
        
        updater _initTargetVersion

        assertEquals(updater _targetVersion, SemVer fromSeq("0.1")))

    testNoVersions := method(
        update := Package with(Directory with("tests/_addons/CFakeAddon"))
        updater := Updater with(self package, update)

        e := try (updater _highestVersion)
        assertEquals(e error type, Updater NoVersionsError type))

    testHighestVersion := method(
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(self package, update)

        updater _targetVersion = SemVer fromSeq("0")

        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.9"))

        updater _targetVersion = SemVer fromSeq("0.1.0-alpha")
        assertEquals(updater _highestVersion, SemVer fromSeq("0.1.0-alpha.3"))

        updater _targetVersion = SemVer fromSeq("0.1.0-rc")
        assertEquals(updater _highestVersion, SemVer fromSeq("0.1.0-rc.2"))

        updater _targetVersion = SemVer fromSeq("0.1")
        assertEquals(updater _highestVersion, SemVer fromSeq("0.1.4"))

        updater _targetVersion = SemVer fromSeq("0.2")
        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.9"))

        updater _targetVersion = SemVer fromSeq("0.2.2")
        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.2"))

        updater _targetVersion = SemVer fromSeq("1")
        assertEquals(updater _highestVersion, SemVer fromSeq("1.0.1"))

        updater _targetVersion = SemVer fromSeq("2.0.0-rc.1")
        assertEquals(updater _highestVersion, SemVer fromSeq("2.0.0-rc.1")))

    testUpdate := method(
        tmpPkgDir := Directory with("tests/_tmp/Test") create remove
        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        package dir copyTo(tmpPkgDir)
        package = Package with(tmpPkgDir)

        installer := Installer with(package)
        installer install(
            Package with(Directory with("tests/_addons/CFakeAddon")))

        dep := package packageNamed("CFakeAddon")
        assertEquals(dep version, SemVer fromSeq("0.1.0"))

        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(package, update)

        updater update
        dep = package packageNamed("CFakeAddon")
        assertEquals(dep version, SemVer fromSeq("0.1.4"))

        package remove)

)
