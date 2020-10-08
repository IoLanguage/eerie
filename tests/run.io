if(System args size > 1) then(
    # Run specific tests.
    System args slice(1) foreach(name,
        try(
            if(name endsWithSeq(".io"),
                # FIXME: This is platform dependent!
                Lobby doFile(System launchPath .. "/" ..  name)
            ,
                Lobby doString(name)
            )
        ) ?showStack
    )
    System exit(if(FileCollector run size > 0, 1, 0))
) else (
    # Run all tests in the current directory.
    System exit(if(TestSuite run size > 0, 1, 0))
)
