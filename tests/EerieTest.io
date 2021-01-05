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
    )

)
