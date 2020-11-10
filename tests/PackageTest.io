PackageTest := UnitTest clone do (

    testInstalledPackages := method(
        package := Package with("tests/_packs/BFakePack")
        assertEquals(2, package packages size)

        expected := list("AFakePack", "CFakePack")
        result := package packages map(manifest name) sort
        assertEquals(expected, result))

    testDirectoryValidation := method(
        e := try (Package with("tests/_fpacks/NotPack"))
        assertEquals(e error type, Package NotPackageError type))

    testDeps := method(
        package := Package with("tests/_packs/AFakePack")
        expected := list()
        
        dep := Package Dependency clone
        dep name = "CFakePack"
        dep version = SemVer fromSeq("0.1")
        dep url = "tests/_packs/CFakePack"
        expected append(dep)
        
        dep = dep clone
        dep name = "BFakePack"
        dep url = "tests/_packs/BFakePack"
        expected append(dep)

        result := package manifest packs

        expected foreach(n, item, 
            assertEquals(item name, result at(n) name)
            assertEquals(item version, result at(n) version)
            assertEquals(item url, result at(n) url)))

    testVersions := method(
        package := Package with("tests/_tmp/CFakePackUpdate")
        assertEquals(23, package versions size))

)

StructureTest := UnitTest clone do (

    testIsPackage := method(
        struct := Package Structure with("tests/_fpacks/NotPack")
        assertFalse(struct isPackage))

    testHasNativeCode := method(
        aStruct := Package Structure with("tests/_packs/AFakePack")
        assertFalse(aStruct hasNativeCode)

        cStruct := Package Structure with("tests/_packs/CFakePack")
        assertTrue(cStruct hasNativeCode))

    testHasBinaries := method(
        aStruct := Package Structure with("tests/_packs/AFakePack")
        assertFalse(aStruct hasBinaries)

        bStruct := Package Structure with("tests/_packs/BFakePack")
        assertTrue(bStruct hasBinaries))


)

ManifestTest := UnitTest clone do (

    testValueForKey := method(
        manifest := Package Manifest clone
        expected := 42
        manifest _map := Map clone atPut(
            "foo", Map clone atPut(
                "bar", Map clone atPut(
                    "baz", expected)))
        assertEquals(expected, manifest valueForKey("foo.bar.baz")))

    testValidation := method(
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
        file := File with("tests/deleteme") setContents(contents)
        e := try (Package Manifest with(file) validate)
        assertEquals(
            e error type,
            Package Manifest InsufficientManifestError type)
        file remove)

    _assertManifestLegal := method(contents,
        file := File with("tests/deleteme") setContents(contents)
        Package Manifest with(file) validate
        file remove)

    testCheckShortenedVersion := method(
        manifest := Package Manifest with(
            File with("tests/_packs/BFakePack/eerie.json"))
        manifest version = SemVer fromSeq("0.1")
        e := try (manifest _checkVersionShortened)
        assertEquals(e error type, 
            Package Manifest VersionIsShortenedError type))

    testCheckReadme := method(
        manifest := Package Manifest with(
            File with("tests/_packs/AFakePack/eerie.json"))
        
        e := try (manifest _checkReadme)
        assertEquals(e error type, Package Manifest ReadmeError type)

        # package with readme field
        manifest = Package Manifest with(
            File with("tests/_packs/DFakePack/eerie.json"))
        readme := manifest file parentDirectory \
            fileNamed("README.md") create remove

        # it doesn't exist
        e := try (manifest _checkReadme)
        assertEquals(e error type, Package Manifest ReadmeError type)

        # make it exists, but empty
        readme create
        e := try (manifest _checkReadme)
        assertEquals(e error type, Package Manifest ReadmeError type)
        
        readme setContents("# " .. manifest name)
        # should pass now
        manifest _checkReadme
        readme remove)

    testCheckLicense := method(
        manifest := Package Manifest with(
            File with("tests/_packs/AFakePack/eerie.json"))
        
        e := try (manifest _checkLicense)
        assertEquals(e error type, Package Manifest LicenseError type)

        # package with license field
        manifest = Package Manifest with(
            File with("tests/_packs/DFakePack/eerie.json"))
        license := manifest file parentDirectory \
            fileNamed("LICENSE") create remove

        # it doesn't exist
        e := try (manifest _checkLicense)
        assertEquals(e error type, Package Manifest LicenseError type)

        # make it exists, but empty
        license create
        e := try (manifest _checkLicense)
        assertEquals(e error type, Package Manifest LicenseError type)
        
        license setContents(manifest name)
        # should pass now
        manifest _checkLicense
        license remove)

    testDescriptionCheck := method(
        # package with empty description
        manifest := Package Manifest with(
            File with("tests/_packs/BFakePack/eerie.json"))

        e := try (manifest _checkDescription)
        assertEquals(e error type, Package Manifest NoDescriptionError type)

        manifest = Package Manifest with(
            File with("tests/_packs/AFakePack/eerie.json"))
        manifest _checkDescription)


)
