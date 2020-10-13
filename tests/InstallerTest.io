Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

InstallerTest := UnitTest clone do (

    testValidation := method(
        installer := Installer clone
        e := try (installer _checkRootSet)
        assertEquals(e error type, Installer RootNotSetError type)

        e := try (installer _checkPackageSet)
        assertEquals(e error type, Installer PackageNotSetError type)

        e := try (installer _checkDestBinNameSet)
        assertEquals(e error type, 
            Installer DestinationBinNameNotSetError type)

        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        installer = Installer with(package)
        e := try (installer install)
        assertEquals(
            e error type, Installer RootNotSetError type))

    testInstall := method(
        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        root := Directory with("tests/installer") 
        installer := Installer with(package) setRoot(root)

        if (root exists, root remove)

        installer install

        # validate that what we installed is a package
        Package with(Directory with(root path .. "/AFakeAddon"))

        # installing it again should raise an exception
        e := try (installer install)
        assertEquals(e error type, Installer DirectoryExistsError type)
        root remove)

    testBuild := method(
        package := Package with(Directory with("tests/_addons/CFakeAddon"))
        initf := package dir directoryNamed("source") \
            fileNamed("IoCFakeAddonInit.c")
        buildDir := package dir directoryNamed("_build")

        if (initf exists, initf remove)
        if (buildDir exists, buildDir remove)

        installer := Installer with(package)

        installer build

        assertTrue(buildDir exists)
        assertTrue(initf exists)

        buildDir remove
        initf remove)

    testInstallBinaries := method(
        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        # we use the package's directory here as a destination, because we just
        # need to check binaries so it's ok here to treat the source as a
        # destination (like we already installed the package there)
        root := Directory with("tests/_addons")
        installer := Installer with(package) setRoot(root)

        e := try (installer _installBinaries)
        assertEquals(e error type, Installer DestinationBinNameNotSetError type)
        
        destBinName := "_bin"

        if (package dir directoryNamed(destBinName) exists, 
            package dir directoryNamed(destBinName) remove)

        installer setDestBinName(destBinName)
        # should return `false`, because the package has no binaries
        assertFalse(installer _installBinaries)

        # a package with binaries
        package = Package with(Directory with("tests/_addons/BFakeAddon"))
        installer setPackage(package) setRoot(root)
        destBinDir := package dir directoryNamed(destBinName)

        if (destBinDir exists, destBinDir remove)

        assertTrue(installer _installBinaries)
        assertTrue(destBinDir exists)

        if (Eerie isWindows) then (
            package binDir files foreach(file,
                destBinDir fileNamed(file name .. ".cmd") exists)
        ) else (
            package binDir files foreach(file,
                # it looks like links don't exist as a file in Io: neither
                # `File exists` nor `File isLink` don't work, so:
                assertTrue(destBinDir files map(name) contains(file name))))

        destBinDir remove)
)
