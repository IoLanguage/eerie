testsDir := Directory with("tests")

query := lazySlot(System args at(1))

testsStartingWith := method(str,
    testsDir files select(file, file baseName beginsWithSeq(str)))

testsEndingWith := method(str,
    testsDir files select(file, file baseName endsWithSeq(str)))

testsStartingAndEndingWith := method(startStr, endStr,
    testsDir files select(file, 
        baseName := file baseName
        baseName beginsWithSeq(startStr) and baseName endsWithSeq(endStr)))

testWithName := method(str, File with(testsDir path .. "/" .. str .. ".io"))

countPlaceholders := method(str, 
    number := 0
    str foreach(char, (char == "*" at(0)) ifTrue(number = number + 1))
    number)

parseQuery := method(str,
    if (countPlaceholders(str) > 1) then (
        Exception raise("Only one '*' placeholder is allowed in query.")
    ) elseif (str beginsWithSeq("*")) then (
        return testsEndingWith(str afterSeq("*"))
    ) elseif (str endsWithSeq("*")) then (
        return testsStartingWith(str beforeSeq("*"))
    ) elseif (str containsSeq("*")) then (
        args := str split("*")
        return testsStartingAndEndingWith(args at(0), args at(1))
    ) else (
        return testWithName(str)))

# run

if(System args size > 1) then (
    # Run specific tests.
    parseQuery(query) foreach(file, try(doFile(file path)) ?showStack)

    System exit(if(FileCollector run size > 0, 1, 0))
) else (
    # Run all tests in the current directory.
    System exit(if(TestSuite run size > 0, 1, 0)))

