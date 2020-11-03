SemVerTest := UnitTest clone do(

    testIlligible := method(
        e := try (SemVer fromSeq(""))
        assertEquals(e error type, SemVer ErrorNotRecognised type)

        e = try (SemVer fromSeq("-"))
        assertEquals(e error type, SemVer ErrorNotRecognised type)

        e = try (SemVer fromSeq("-beta"))
        assertEquals(e error type, SemVer ErrorNotRecognised type)

        e = try (SemVer fromSeq("-beta.1"))
        assertEquals(e error type, SemVer ErrorNotRecognised type)

        e = try (SemVer fromSeq("beta.1"))
        assertEquals(e error type, SemVer ErrorNotRecognised type)

        e = try (SemVer fromSeq("1-beta"))
        assertEquals(e error type, SemVer ErrorIlligibleVersioning type)

        e = try (SemVer fromSeq("1.0-beta.1"))
        assertEquals(e error type, SemVer ErrorIlligibleVersioning type)

        e = try (SemVer fromSeq("1.0.0-gamma.1"))
        assertEquals(e error type, SemVer ErrorParsePre type))

    testParse := method(
        ver := SemVer fromSeq("1")
        assertEquals(ver major, 1)
        assertEquals(ver minor, nil)
        assertEquals(ver patch, nil)
        assertEquals(ver pre, nil)
        assertEquals(ver preNumber, nil)
        assertFalse(ver isPre)

        ver = SemVer fromSeq("1.0")
        assertEquals(ver major, 1)
        assertEquals(ver minor, 0)
        assertEquals(ver patch, nil)
        assertEquals(ver pre, nil)
        assertEquals(ver preNumber, nil)
        assertFalse(ver isPre)

        ver = SemVer fromSeq("1.0.90")
        assertEquals(ver major, 1)
        assertEquals(ver minor, 0)
        assertEquals(ver patch, 90)
        assertEquals(ver pre, nil)
        assertEquals(ver preNumber, nil)
        assertFalse(ver isPre)

        ver = SemVer fromSeq("1.0.90-beta")
        assertEquals(ver major, 1)
        assertEquals(ver minor, 0)
        assertEquals(ver patch, 90)
        assertEquals(ver pre, "BETA")
        assertEquals(ver preNumber, nil)
        assertTrue(ver isPre)

        ver = SemVer fromSeq("1.0.90-Alpha.101")
        assertEquals(ver major, 1)
        assertEquals(ver minor, 0)
        assertEquals(ver patch, 90)
        assertEquals(ver pre, "ALPHA")
        assertEquals(ver preNumber, 101)
        assertTrue(ver isPre))

    testAsSeq := method(
        ver := SemVer fromSeq("0.1.1-Beta.15")
        assertEquals("0.1.1-beta.15", ver asSeq)

        ver = SemVer fromSeq("0.1.1")
        assertEquals("0.1.1", ver asSeq)

        ver = SemVer fromSeq("0.1")
        assertEquals("0.1", ver asSeq))

    testComparisons := method(
        e := try (SemVer fromSeq("1") == 1)
        assertEquals(e error type, SemVer ErrorWrongType type)

        assertTrue(SemVer fromSeq("1") == SemVer fromSeq("1"))
        assertTrue(SemVer fromSeq("1") > SemVer fromSeq("1.1"))
        assertTrue(SemVer fromSeq("1") > SemVer fromSeq("1.1.1"))
        assertTrue(SemVer fromSeq("1") > SemVer fromSeq("1.1.1-rc"))
        assertTrue(SemVer fromSeq("1") > SemVer fromSeq("1.1.1-rc.1"))

        assertTrue(SemVer fromSeq("1.1") == SemVer fromSeq("1.1"))
        assertTrue(SemVer fromSeq("1.0") < SemVer fromSeq("1.1"))
        assertTrue(SemVer fromSeq("1.0.90") < SemVer fromSeq("1.1"))
        assertTrue(SemVer fromSeq("1.0.90-beta") < SemVer fromSeq("1.1"))
        assertTrue(SemVer fromSeq("1.0.90-beta.2") < SemVer fromSeq("1.1"))

        assertTrue(SemVer fromSeq("1.1.1") == SemVer fromSeq("1.1.1"))
        assertTrue(SemVer fromSeq("1.1.1") != SemVer fromSeq("1.1.1-beta"))
        assertTrue(SemVer fromSeq("1.1.2") > SemVer fromSeq("1.1.1"))
        assertTrue(SemVer fromSeq("1.1.2") > SemVer fromSeq("1.1.2-alpha"))
        assertTrue(SemVer fromSeq("1.1.2") > SemVer fromSeq("1.1.2-alpha.12"))

        assertTrue(SemVer fromSeq("1.1.1-rc") == SemVer fromSeq("1.1.1-rc"))
        assertTrue(SemVer fromSeq("1.1.1-alpha") > SemVer fromSeq("1.1.0"))
        assertTrue(SemVer fromSeq("1.1.1-beta") > SemVer fromSeq("1.1.1-alpha"))
        assertTrue(SemVer fromSeq("1.1.1-beta") < SemVer fromSeq("1.1.1-rc"))
        assertTrue(SemVer fromSeq("1.1.1-rc") > SemVer fromSeq("1.1.1-rc.99"))
        assertTrue(SemVer fromSeq("1.1.1-rc.2") > SemVer fromSeq("1.1.1-rc.1"))
        assertTrue(SemVer fromSeq("1.1.1-rc.1") > SemVer fromSeq("1.1.1-beta"))
        assertTrue(
            SemVer fromSeq("1.1.1-rc.1") != SemVer fromSeq("1.1.1-rc.2")))

    testPreComparison := method(
        assertEquals(
            0,
            SemVer fromSeq("1") _comparePre(SemVer fromSeq("1.0.0") pre))

        assertEquals(
            -1,
            SemVer fromSeq("1.0.0-alpha") \
                _comparePre(SemVer fromSeq("1.0.0-beta") pre))

        assertEquals(
            1,
            SemVer fromSeq("1.0.0-rc") \
                _comparePre(SemVer fromSeq("1.0.0-alpha") pre)))

    testLoyality := method(
        assertEquals(
            SemVer fromSeq("v.1.0.1"),
            SemVer fromSeq("1.0.1"))

        assertEquals(
            SemVer fromSeq("Version 10.0.1-Beta"),
            SemVer fromSeq("ver.10.0.1-BETA"))

        assertEquals(
            SemVer fromSeq("Release version 99.0.1-RC.11"),
            SemVer fromSeq("V99.0.1-rc.11")))

    testNextVersion := method(
        assertEquals(SemVer fromSeq("1") nextVersion, SemVer fromSeq("2"))
        assertEquals(SemVer fromSeq("1.0") nextVersion, SemVer fromSeq("1.1"))
        assertEquals(
            SemVer fromSeq("1.0.0") nextVersion,
            SemVer fromSeq("1.0.1"))
        assertEquals(
            SemVer fromSeq("1.0.0-alpha") nextVersion,
            SemVer fromSeq("1.0.0-beta"))
        assertEquals(
            SemVer fromSeq("1.0.0-beta") nextVersion,
            SemVer fromSeq("1.0.0-rc"))
        assertEquals(
            SemVer fromSeq("1.0.0-beta.1") nextVersion,
            SemVer fromSeq("1.0.0-beta.2")))

    testIsShorened := method(
        assertTrue(SemVer fromSeq("1") isShortened)
        assertTrue(SemVer fromSeq("1.0") isShortened)
        assertFalse(SemVer fromSeq("1.0.0") isShortened)
        assertTrue(SemVer fromSeq("1.0.0-beta") isShortened)
        assertFalse(SemVer fromSeq("1.0.0-beta.1") isShortened))

)
