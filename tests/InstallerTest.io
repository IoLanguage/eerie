Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

InstallerTest := UnitTest clone do (

    testValidation := method(
        installer := Installer clone
        e := try (installer _checkDestinationSet)
        assertEquals(e error type, Installer DestinationNotSetError type)

        e := try (installer _checkPackageSet)
        assertEquals(e error type, Installer PackageNotSetError type)

        e := try (installer _checkDestBinNameSet)
        assertEquals(e error type, 
            Installer DestinationBinNameNotSetError type)

        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        installer = Installer with(package)
        e := try (installer install)
        assertEquals(
            e error type, Installer DestinationNotSetError type))

    testInstall := method(
        package := Package with(Directory with("tests/_addons/AFakeAddon"))

        destination := Directory with("tests/installer") 
        if(destination exists, destination remove)

        installer := Installer with(package) setDestination(destination)

        installer install

        # validate that what we installed is a package
        Package with(Directory with(destination path .. "/AFakeAddon"))

        # installing it again should raise an exception
        e := try (installer install)
        assertEquals(e error type, Installer DirectoryExistsError type)
        destination remove)

    testCompile := method()

    testInstallBinaries := method()
)
