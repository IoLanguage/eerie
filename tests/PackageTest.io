PackageTest := UnitTest clone do (

    testInstalledPackages := method(
        Eerie Rainbow redBg bold
        " I'm broken Package packages test. Fix me, bro " println
        Eerie Rainbow reset
        return

        package := Package with("tests/_packs/BFakePack")
        assertEquals(2, package packages size)

        expected := list("AFakePack", "CFakePack")
        result := package packages map(struct manifest name) sort
        assertEquals(expected, result))

    testVersions := method(
        package := Package with("tests/_tmp/CFakePackUpdate")
        assertEquals(23, package versions size))

)
