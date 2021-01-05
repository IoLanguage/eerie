EerieTest := UnitTest clone do (

    testExceptionWithoutEeridir := method(
        backup := System getEnvironmentVariable("EERIEDIR")
        System setEnvironmentVariable("EERIEDIR", "")
        e := try (Eerie init)
        System setEnvironmentVariable("EERIEDIR", backup)
        assertEquals(e error type, Eerie EerieDirNotSetError type))

    testUpgrade := method(
        assertEquals(
            "#{Eerie root}/_build/_tmp/upgrade" interpolate, 
            Eerie _downloadDir path)

        dest := Directory with("tests/manifest")
        manifest := Package Structure Manifest with(
            dest fileNamed(Package Structure Manifest fileName))
        updateManifest := Eerie _prepareUpdateManifest(dest)
        expected := Package global struct manifest packs keys 
        expected appendSeq(manifest packs keys)
        
        assertEquals(
            updateManifest packs keys sort,
            expected sort)

        assertFalse(
            Eerie _outdatedItems map(name) \
                containsAny(list(".", "..", "db", "_backup", "_build"))))

    testBackup := method(
        dir := Directory with("tests/_backup")
        Eerie _backup(dir)

        manifest := Package Structure Manifest with(
            dir fileNamed(Package Structure Manifest fileName))

        assertEquals(
            manifest file contents,
            Package global struct manifest file contents))

)
