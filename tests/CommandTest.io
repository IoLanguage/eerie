Importer addSearchPath("io/Eerie/Builder")

CommandTest := UnitTest clone do (

    Command

    _package := Package with(Directory with("tests/_addons/AFakeAddon"))

    _depsManager := DependencyManager with(_package)

    testCompilerCommand := method(
        command := CompilerCommand with(self _package, self _depsManager)

        e := try (command asSeq)
        assertEquals(e error type, CompilerCommand SrcNotSetError type)

        src := File with("test.c")
        command setSrc(src)

        command addDefine("COMMAND_TEST")

        expected := if (Eerie platform == "windows", 
            "-DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE " .. \
                "-DCOMMAND_TEST",
            "-DSANE_POPEN -DIOBINDINGS -DCOMMAND_TEST")

        assertEquals(expected, command _definesFlags) 

        expected = "tests/_addons/AFakeAddon/_build/objs/test.o " .. \
            "tests/_addons/AFakeAddon/source/test.c"

        assertTrue(command asSeq endsWithSeq(expected)))

    testStaticLinkerCommand := method(
        # check it works at least
        command := StaticLinkerCommand with(self _package)
        command asSeq)

    testDynamicLinkerCommand := method(
        # check it works at least
        command := DynamicLinkerCommand with(self _package, self _depsManager)
        command asSeq)

)
