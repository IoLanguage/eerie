UpdaterTest := UnitTest clone do (

    package := Package with(Directory with("tests/_addons/AFakeAddon"))

    testCheckInstalled := method(
        update := Package with(Directory with("tests/_tmp/CFakeAddonUpdate"))
        updater := Updater with(self package, update)

        e := try (updater _checkInstalled)
        assertEquals(e error type, Updater NotInstalledError type))

    testNoVersions := method(
        update := Package with(Directory with("tests/_addons/CFakeAddon"))
        updater := Updater with(self package, update)

        e := try (updater _checkHasVersions)
        assertEquals(e error type, Updater NoVersionsError type))

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
