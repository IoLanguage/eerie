//metadoc TestsRunner category API
//metadoc TestsRunner description Run tests in specified directory.

TestsRunner := Object clone do (
    /*doc TestsRunner dir 
    Directory with tests, which the runner will run. Default to `./tests`.*/
    //doc TestsRunner setDir `dir` setter.
    dir ::= Directory with("tests")

    /*doc TestsRunner run(query)
    Runs tests in `TestsRunner dir` or specific tests if `query` is not `nil`.

    For example, you have tests: FooTest.io, BarTest.io, BazTest.io. When you
    execute this method with query "`Foo*`", it will run FooTest.io. For
    "`Ba*`", it will run BarTest.io and BazTest.io. And it will run all tests
    when query is "`*Test`".

    Only one "*" placeholder allowed in query at the moment. Will raise
    `TestsRunner PlaceholderError` if you try more.

    If `TestsRunner dir` has a file called `setup.io`, it will run this file
    before tests.

    Returns `true` if tests ran successful and `false` if any of tests failed.*/
    run := method(query,
        self _checkDir
        self _runSetup
        if(query isNil or query isEmpty,
            return self _runAll,
            return self _runQuery(query)))

    _checkDir := method(
        if (self dir isNil, Exception raise(DirectoryNotSetError with("")))
        if (self dir exists not, 
            Exception raise(DirectoryNotExistsError with(self dir path))))

    # run setup script if it exists
    _runSetup := method(
        file := self dir fileNamed("setup.io")
        if (file exists, Lobby doFile(file path)))

    _runAll := method(
        DirectoryCollector setPath(self dir path)
        DirectoryCollector run size == 0)

    _runQuery := method(query,
        self _parseQuery(query) foreach(file, 
            try(Lobby doFile(file path)) ?showStack)

        FileCollector run size == 0)

    _parseQuery := method(str,
        if (self _countPlaceholders(str) > 1) then (
            Exception raise(PlaceholderError with(""))
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
        self dir files select(file, file baseName endsWithSeq(str)))

    _testsStartingWith := method(str,
        self dir files select(file, file baseName beginsWithSeq(str)))


    _testsStartingAndEndingWith := method(startStr, endStr,
        self dir files select(file, 
            baseName := file baseName
            baseName beginsWithSeq(startStr) and baseName endsWithSeq(endStr)))

    _testWithName := method(str, 
        File with(self dir path .. "/" .. str .. ".io"))

)

# TestsRunner error types
TestsRunner do (

    PlaceholderError := Eerie Error clone setErrorMsg(
        "Only one '*' placeholder is allowed in query.")

    DirectoryNotSetError := Eerie Error clone setErrorMsg(
        "Tests directory not set.")

    DirectoryNotExistsError := Eerie Error clone setErrorMsg(
        "Directory '#{call evalArgAt(0)}' not found.")

)
