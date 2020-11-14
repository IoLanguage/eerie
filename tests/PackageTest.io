PackageTest := UnitTest clone do (

    testInstalledPackages := method(
        Eerie Rainbow redBg bold
        " I'm broken Package packages test. Fix me, bro :`(" println
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

    testChildren := method(
        package := Package with("tests/installed/AFakePack")
        expected := list("AFakePack", "BFakePack")
        assertEquals(expected,
            package children at("CFakePack") children keys sort)

        expected = list("AFakePack", "CFakePack")
        assertEquals(expected, 
            package children at("BFakePack") children keys sort)

        self _checkParents(package)

        assertFalse(package recursive)

        # BFakePack recursivity

        assertFalse(package children at("BFakePack") recursive)
        assertTrue(
            package children at("BFakePack") children at("AFakePack") recursive)

        package children \
            at("BFakePack") children \
                at("CFakePack") children foreach(name, child,
            assertTrue(child recursive))


        # CFakePack recursivity

        assertFalse(package children at("CFakePack") recursive)
        assertTrue(
            package children at("CFakePack") children at("AFakePack") recursive)

        package children \
            at("CFakePack") children \
                at("BFakePack") children foreach(name, child,
            assertTrue(child recursive)))

    _checkParents := method(package,
        package children ?foreach(name, child,
            if (child recursive not, self _checkParents(child))
            assertEquals(child parent, package)))

    testMissing := method(
        package := Package with("tests/_packs/AFakePack")
        assertEquals(package missing, package struct manifest packs values))

    testChanged := method(
        package := Package with("tests/installed/AFakePack")
        assertEquals("DFakePack", package changed at(0) name))

)
