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

    testDirectoryValidation := method(
        e := try (Package with(Directory with("tests/_faddons/NotAddon")))
        assertEquals(e error type, Package NotPackageError type))

    testManifestValidator := method(
        manifest := File with("tests/deleteme") setContents("{}")
        e := try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{"name": "Test"}""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0"
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test"
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {}
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                    "git": {}
                }
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                }
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": ""
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        # shouldn't raise an exception if protos is empty array
        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": []
            }""")
        Package ManifestValidator with(manifest) validate

        # dependencies is optional, so an empty array shouldn't raise an
        # exception
        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "addons": []
            }""")
        Package ManifestValidator with(manifest) validate

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "addons": [ { } ] 
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "addons": [
                    { 
                        "name": "Test"
                    }
                ]
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "addons": [
                    { 
                        "name": "Test",
                        "version": "0.1"
                    }
                ]
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertEquals(
            e error type,
            Package ManifestValidator InsufficientManifestError type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
            },
            "protos": [],
            "addons": [
                    { 
                        "name": "Test",
                        "version": "0.1",
                        "path": {
                            "dir": "tests/_addons/AFakeAddon"
                        }
                    }
                ]
            }""")
        e = try (Package ManifestValidator with(manifest) validate)
        assertTrue(e isNil)

        manifest close remove
    )

)
