CommandTest := UnitTest clone do (

    _package := Package with("tests/_packs/AFakePack")

    _depsManager := Builder DependencyManager with(_package)

    testCompilerCommand := method(
        command := Builder CompilerCommand with(
            self _package, 
            self _depsManager)

        e := try (command asSeq)
        assertEquals(e error type, Builder CompilerCommand SrcNotSetError type)

        src := File with("test.c")
        command setSrc(src)

        command addDefine("COMMAND_TEST")

        expected := if (Eerie platform == "windows", 
            "-DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE " .. \
                "-DCOMMAND_TEST",
            "-DSANE_POPEN -DIOBINDINGS -DCOMMAND_TEST")

        assertEquals(expected, command _definesFlags) 

        expected = "tests/_packs/AFakePack/_build/objs/test.o " .. \
            "tests/_packs/AFakePack/source/test.c"

        assertTrue(command asSeq endsWithSeq(expected)))

    testStaticLinkerCommand := method(
        # check it works at least
        command := Builder StaticLinkerCommand with(self _package)
        command asSeq)

    testDynamicLinkerCommand := method(
        # check it works at least
        command := Builder DynamicLinkerCommand with(
            self _package,
            self _depsManager)
        command asSeq)

)
