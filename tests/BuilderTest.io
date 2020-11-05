BuilderTest := UnitTest clone do (

    testBuild := method(
        package := Package with(Directory with("tests/_addons/CFakeAddon"))
        initf := package sourceDir fileNamed("IoCFakeAddonInit.c")
        buildDir := package buildDir

        if (initf exists, initf remove)
        if (buildDir exists, buildDir remove)

        builder := Builder with(package)

        builder build(package)

        assertTrue(buildDir exists)
        assertTrue(initf exists)

        buildDir remove
        initf remove)

)
