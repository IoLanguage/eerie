Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

PackageInstallerTest := UnitTest clone do (

    testCheckDestination := method(
        installer := PackageInstaller clone
        e := try (installer _checkDestination)
        assertEquals(e error type, PackageInstaller DestinationNotSetError type)

        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        e := try (installer install(package))
        assertEquals(
            e error type, PackageInstaller DestinationNotSetError type))

    testInstall := method(
        package := Package with(Directory with("tests/_addons/AFakeAddon"))

        destination := Directory with("tests/installer") 
        if(destination exists, destination remove)

        installer := PackageInstaller clone setDestination(destination)

        installer install(package)

        # validate that what we installed is a package
        Package with(Directory with(destination path .. "/AFakeAddon"))

        e := try (installer install(package))
        assertEquals(e error type, PackageInstaller DirectoryExistsError type)
        destination remove)

    testCompile := method()

    testInstallBinaries := method()
)
