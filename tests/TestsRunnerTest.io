TestsRunnerTest := UnitTest clone do (

    testCheckDir := method(
        runner := TestsRunner clone
        runner setDir(nil)

        e := try (runner run)
        assertEquals(e error type, TestsRunner DirectoryNotSetError type)

        runner setDir(Directory with("shouldntexist"))
        e := try (runner run)
        assertEquals(e error type, TestsRunner DirectoryNotExistsError type))

    testCheckQuery := method(
        runner := TestsRunner clone

        e := try (runner run("*something*"))
        assertEquals(e error type, TestsRunner PlaceholderError type))

)
