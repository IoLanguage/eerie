BuilderTest := UnitTest clone do (

    testBuild := method(
        package := Package with("tests/_packs/CFakePack")
        initf := package struct source fileNamed("IoCFakePackInit.c")
        buildDir := package struct build root

        if (initf exists, initf remove)
        if (buildDir exists, buildDir remove)

        builder := Builder with(package)

        builder build(package)

        assertTrue(buildDir exists)
        assertTrue(initf exists)

        buildDir remove
        initf remove)

)
