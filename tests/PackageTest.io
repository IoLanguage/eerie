PackageTest := UnitTest clone do (

    testInstalledPackages := method(
        package := Package with("tests/_packs/BFakePack")
        assertEquals(2, package packages size)

        expected := list("AFakePack", "CFakePack")
        result := package packages map(name) sort
        assertEquals(expected, result))

    testHasNativeCode := method(
        aPackage := Package with("tests/_packs/AFakePack")
        assertFalse(aPackage hasNativeCode)

        cPackage := Package with("tests/_packs/CFakePack")
        assertTrue(cPackage hasNativeCode))

    testHasBinaries := method(
        aPackage := Package with("tests/_packs/AFakePack")
        assertFalse(aPackage hasBinaries)

        bPackage := Package with("tests/_packs/BFakePack")
        assertTrue(bPackage hasBinaries))

    testDeps := method(
        package := Package with("tests/_packs/AFakePack")
        expected := list()
        
        dep := Package DepDesc clone
        dep name = "CFakePack"
        dep version = SemVer fromSeq("0.1")
        dep url = "tests/_packs/CFakePack"
        expected append(dep)
        
        dep = dep clone
        dep name = "BFakePack"
        dep url = "tests/_packs/BFakePack"
        expected append(dep)

        result := package deps

        expected foreach(n, item, 
            assertEquals(item name, result at(n) name)
            assertEquals(item version, result at(n) version)
            assertEquals(item url, result at(n) url)))

    testHasDep := method(
        package := Package with("tests/_packs/AFakePack")

        e := try (package checkHasDep("shouldntexist"))
        assertEquals(e error type, Package NoDependencyError type))

    testVersions := method(
        package := Package with("tests/_tmp/CFakePackUpdate")
        assertEquals(23, package versions size))

    testHighestVersion := method(
        package := Package with("tests/_packs/AFakePack")

        package versions := list()
        assertTrue(package highestVersionFor isNil)
        assertTrue(package highestVersionFor(SemVer fromSeq("0.1.0")) isNil)

        package versions := list(
            SemVer fromSeq("0.1.0"),
            SemVer fromSeq("0.1.1"),
            SemVer fromSeq("0.1.2"),
            SemVer fromSeq("0.1.3-alpha.1"),
            SemVer fromSeq("0.1.3-beta.1"),
            SemVer fromSeq("0.1.3-rc.1"),
            SemVer fromSeq("0.1.3-rc.2"),
            SemVer fromSeq("0.2.0"),
            SemVer fromSeq("0.2.1"),
            SemVer fromSeq("1.0.0-rc.1"))

        assertEquals(package highestVersionFor, SemVer fromSeq("1.0.0-rc.1"))
        assertEquals(
            package highestVersionFor(SemVer fromSeq("0")),
            SemVer fromSeq("0.2.1"))
        assertEquals(
            package highestVersionFor(SemVer fromSeq("0.1")),
            SemVer fromSeq("0.1.2"))
        assertEquals(
            package highestVersionFor(SemVer fromSeq("0.1.3-rc")),
            SemVer fromSeq("0.1.3-rc.2"))
        assertEquals(
            package highestVersionFor(SemVer fromSeq("0.2.0")),
            SemVer fromSeq("0.2.0"))
        assertEquals(
            package highestVersionFor(SemVer fromSeq("0.2")),
            SemVer fromSeq("0.2.1")))

    testDirectoryValidation := method(
        e := try (Package with("tests/_fpacks/NotPack"))
        assertEquals(e error type, Package NotPackageError type))

    testManifestValidator := method(
        self _assertManifestError("{}")

        self _assertManifestError("""{"name": "Test"}""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0"
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test"
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": ""
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package"
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": ""
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": [ { } ] 
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": [
                    { 
                        "name": "Test"
                    }
                ]
            }""")

        # shouldn't raise an exception if protos is empty array
        self _assertManifestLegal("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": []
            }""")

        # dependencies is optional, so an empty array shouldn't raise an
        # exception
        self _assertManifestLegal("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": []
            }""")

        # this shouldn't raise an exception, the dependency supposed to be
        # published
        self _assertManifestLegal("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "packs": [
                    { 
                        "name": "Test",
                        "version": "0.1"
                    }
                ]
            }"""))

    _assertManifestError := method(contents,
        manifest := File with("tests/deleteme") setContents(contents)
        e := try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)
        manifest remove)

    _assertManifestLegal := method(contents,
        manifest := File with("tests/deleteme") setContents(contents)
        Package ManifestValidator with(manifest) validate
        manifest remove)

)
