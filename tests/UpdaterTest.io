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

        assertEquals(41, updater _availableVersions size))

    testHighestUpdate := method(
        target := Package with(Directory with("tests/_addons/CFakeAddon"))
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        targetVer := SemVer fromSeq("0.1")
        updater := Updater with(target, update, targetVer)

        updater _highestVersion println

    )
)
