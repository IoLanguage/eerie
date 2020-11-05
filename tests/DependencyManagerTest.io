Importer addSearchPath("io/Eerie/Builder")

DependencyManagerTest := UnitTest clone do (

    testCheckMissing := method(
        package := Package with("tests/_addons/AFakeAddon")
        deps := DependencyManager with(package)

        # shouldn't raise exceptions by default
        deps checkMissing

        # headers

        reset := deps _headers clone

        deps dependsOnHeader("dontexist.h")

        e := try (deps checkMissing)
        assertEquals(
            e error type, 
            DependencyManager MissingHeadersError type)

        deps _headers = reset

        # libs

        reset = deps _libs clone

        deps dependsOnLib("dontexist")

        e = try (deps checkMissing)
        assertEquals(e error type, DependencyManager MissingLibsError type)

        deps _libs = reset

        # frameworks

        reset = deps _frameworks clone

        deps dependsOnFramework("dontexist.framework")

        e = try (deps checkMissing)
        assertEquals(
            e error type, 
            DependencyManager MissingFrameworksError type)

        deps _frameworks = reset

        package buildDir remove)

)
