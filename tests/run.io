Runner := Object clone do (
    _testsDir := Directory with("tests")

    _query := System args at(1)

    run := method(
        self _runSetup
        if(self _query isNil not,
            self _runQuery,
            self _runAll))

    # run setup script if it exists
    _runSetup := method(
        file := File with(System launchPath .. "/setup.io")
        if (file exists, Lobby doFile(file path)))

    _runQuery := method(
        self _parseQuery(self _query) foreach(file, 
            try(Lobby doFile(file path)) ?showStack)

        System exit(if(FileCollector run size > 0, 1, 0)))

    _parseQuery := method(str,
        if (self _countPlaceholders(str) > 1) then (
            Exception raise("Only one '*' placeholder is allowed in query.")
        ) elseif (str beginsWithSeq("*")) then (
            return self _testsEndingWith(str afterSeq("*"))
        ) elseif (str endsWithSeq("*")) then (
            return self _testsStartingWith(str beforeSeq("*"))
        ) elseif (str containsSeq("*")) then (
            args := str split("*")
            return self _testsStartingAndEndingWith(args at(0), args at(1))
        ) else (
            return self _testWithName(str)))

    _countPlaceholders := method(str, 
        number := 0
        str foreach(char, (char == "*" at(0)) ifTrue(number = number + 1))
        number)

    _testsEndingWith := method(str,
        self _testsDir files select(file, file baseName endsWithSeq(str)))

    _testsStartingWith := method(str,
        self _testsDir files select(file, file baseName beginsWithSeq(str)))


    _testsStartingAndEndingWith := method(startStr, endStr,
        self _testsDir files select(file, 
            baseName := file baseName
            baseName beginsWithSeq(startStr) and baseName endsWithSeq(endStr)))

    _testWithName := method(str, 
        File with(self _testsDir path .. "/" .. str .. ".io"))

    _runAll := method(System exit(if(TestSuite run size > 0, 1, 0)))

)

Runner run
