PublisherTest := UnitTest clone do (

    testPackageSet := method(
        publisher := Publisher with
        e := try (publisher _checkPackageSet)
        assertEquals(e error type, Publisher PackageNotSetError type))

)
