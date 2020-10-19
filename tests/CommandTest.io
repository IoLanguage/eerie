Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")
Importer addSearchPath("io/Eerie/Builder")

CommandTest := UnitTest clone do (

    Command

    testCompilerCommand := method(
        package := Package with(Directory with("tests/_addons/AFakeAddon"))
        depsManager := DependencyManager with(package)
        command := CompilerCommand with(package, depsManager)

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

        command asSeq println

        expected = "tests/_addons/AFakeAddon/_build/objs/test.o " .. \
            "tests/_addons/AFakeAddon/source/test.c"

        assertTrue(command asSeq endsWithSeq(expected)))
)
