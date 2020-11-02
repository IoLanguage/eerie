Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

PackageTest := UnitTest clone do (

    testInstalledPackages := method(
        package := Package with(Directory with("tests/_addons/BFakeAddon"))
        assertEquals(2, package packages size)

        expected := list("AFakeAddon", "CFakeAddon")
        result := package packages map(name) sort
        assertEquals(expected, result))

    testHasNativeCode := method(
        aPackage := Package with(Directory with("tests/_addons/AFakeAddon"))
        assertFalse(aPackage hasNativeCode)

        cPackage := Package with(Directory with("tests/_addons/CFakeAddon"))
        assertTrue(cPackage hasNativeCode))

    testHasBinaries := method(
        aPackage := Package with(Directory with("tests/_addons/AFakeAddon"))
        assertFalse(aPackage hasBinaries)

        bPackage := Package with(Directory with("tests/_addons/BFakeAddon"))
        assertTrue(bPackage hasBinaries))

    testHasDep := method(
        package := Package with(Directory with("tests/_addons/AFakeAddon"))

        e := try (package checkHasDep("shouldntexist"))
        assertEquals(e error type, Package NoDependencyError type))

    testDirectoryValidation := method(
        e := try (Package with(Directory with("tests/_faddons/NotAddon")))
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
            "addons": [ { } ] 
            }""")

        self _assertManifestError("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "addons": [
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
            "addons": []
            }""")

        # this shouldn't raise an exception, the dependency supposed to be
        # published
        self _assertManifestLegal("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "url": "path/to/package",
            "protos": [],
            "addons": [
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
