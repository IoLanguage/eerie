Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

UpdaterTest := UnitTest clone do (
    
    testSamePackage := method(
        target := Package with(Directory with("tests/_addons/AFakeAddon"))
        update := Package with(Directory with("tests/_addons/BFakeAddon"))
        targetVer := SemVer fromSeq("0.1")

        e := try (Updater with(target, update, targetVer))
        assertEquals(e error type, Updater DifferentPackageError type))

    testAvailableVersions := method(
        target := Package with(Directory with("tests/_addons/CFakeAddon"))
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        targetVer := SemVer fromSeq("0.1")
        updater := Updater with(target, update, targetVer)

        assertEquals(22, updater _availableVersions size))

    testHighestVersion := method(
        target := Package with(Directory with("tests/_addons/CFakeAddon"))
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        targetVer := SemVer fromSeq("0")
        updater := Updater with(target, update, targetVer)

        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.9"))

        updater setTargetVersion(SemVer fromSeq("0.1.0-alpha"))
        assertEquals(updater _highestVersion, SemVer fromSeq("0.1.0-alpha.3"))

        updater setTargetVersion(SemVer fromSeq("0.1.0-rc"))
        assertEquals(updater _highestVersion, SemVer fromSeq("0.1.0-rc.2"))

        updater setTargetVersion(SemVer fromSeq("0.1"))
        assertEquals(updater _highestVersion, SemVer fromSeq("0.1.3"))

        updater setTargetVersion(SemVer fromSeq("0.2"))
        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.9"))

        updater setTargetVersion(SemVer fromSeq("0.2.2"))
        assertEquals(updater _highestVersion, SemVer fromSeq("0.2.2"))

        updater setTargetVersion(SemVer fromSeq("1"))
        assertEquals(updater _highestVersion, SemVer fromSeq("1.0.1"))

        updater setTargetVersion(SemVer fromSeq("2.0.0-rc.1"))
        assertEquals(updater _highestVersion, SemVer fromSeq("2.0.0-rc.1")))

)
