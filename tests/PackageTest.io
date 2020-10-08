Importer addSearchPath("io/Eerie")

PackageTest := UnitTest clone do (

    testDirectoryValidation := method(
        e := try (Package with(Directory with("tests/_faddons/NotAddon")))
        assertEquals(e type, Eerie NotPackageException type))

    testManifestValidation := method(
        manifest := File with("tests/deleteme") setContents("{}")
        e := try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{"name": "Test"}""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0"
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test"
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {}
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                    "git": {}
                }
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                }
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": ""
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "dependencies": ""
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "dependencies": { "packages": [ { } ] }
            }""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "dependencies": { 
            "packages": [
                    { 
                        "name": "Test"
                    }
                ]
            }}""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
                },
            "protos": [],
            "dependencies": { 
            "packages": [
                    { 
                        "name": "Test",
                        "version": "0.1"
                    }
                ]
            }}""")
        e = try (Package _validateManifest(manifest))
        assertEquals(e type, Eerie InsufficientManifestException type)

        manifest setContents("""{
            "name": "Test", 
            "version": "0.1.0",
            "author": "Test",
            "path": {
                "dir": "test"
            },
            "protos": [],
            "dependencies": { 
            "packages": [
                    { 
                        "name": "Test",
                        "version": "0.1",
                        "path": {
                            "dir": "tests/_addons/AFakeAddon"
                        }
                    }
                ]
            }}""")
        e = try (Package _validateManifest(manifest))
        assertTrue(e isNil)

        manifest close remove
    )
)
