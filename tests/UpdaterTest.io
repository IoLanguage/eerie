Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

UpdaterTest := UnitTest clone do (

    package := Package with(Directory with("tests/_addons/AFakeAddon"))

    setUp := method(
        dep := self package packageNamed("CFakeAddon")
        if (dep isNil not, self package removePackage(dep)))

    tearDown := method(
        dep := self package packageNamed("CFakeAddon")
        if (dep isNil not, self package removePackage(dep)))
    
    testHasDep := method(
        update := Package with(Directory with("tests/_addons/DFakeAddon"))
        updater := Updater with(self package, update)

        e := try (updater _checkHasDep)
        assertEquals(e error type, Updater NoDependencyError type))

    testCheckInstalled := method(
        assertTrue(self package packageNamed("CFakeAddon") isNil)

        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(self package, update)
        updater _checkInstalled

        assertFalse(self package packageNamed("CFakeAddon") isNil))

    testInitTargetVersion := method(
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(self package, update)

        assertTrue(updater _targetVersion isNil)
        
        updater _initTargetVersion

        assertEquals(updater _targetVersion, SemVer fromSeq("0.1")))

    testAvailableVersions := method(
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(self package, update)

        assertEquals(22, updater _availableVersions size))

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
        assertEquals(updater _highestVersion, SemVer fromSeq("0.1.3"))

        updater _targetVersion = SemVer fromSeq("0.2")
        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.9"))

        updater _targetVersion = SemVer fromSeq("0.2.2")
        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.2"))

        updater _targetVersion = SemVer fromSeq("1")
        assertEquals(updater _highestVersion, SemVer fromSeq("1.0.1"))

        updater _targetVersion = SemVer fromSeq("2.0.0-rc.1")
        assertEquals(updater _highestVersion, SemVer fromSeq("2.0.0-rc.1")))

)
