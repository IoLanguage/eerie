//metadoc SemVer category API
/*metadoc SemVer description 
Semantic verion parser. It's able to parse semantic versions of type `A.B.C-D.E`
where:

- `A` - the major verion number
- `B` - the minor version number
- `C` - the patch number
- `D` - pre-release status, which is case-insensitive `alpha`, `beta` or `rc`
- `E` - the pre-release version number

Shortened versions are allowed too (i.e. `0.1.0`, `0.1`, `0.1.0-alpha`). But it
should be shortened from the end. For example, `0.1.0-beta` is legal, but
`0.1-beta` isn't.
*/

SemVer := Object clone do(

    //doc SemVer major Major version number (i.e. `A` in `A.B.C-D.E`).
    major := nil

    //doc SemVer minor Minor version number (i.e. `B` in `A.B.C-D.E`).
    minor := nil

    //doc SemVer patch Patch number (i.e. `B` in `A.B.C-D.E`).
    patch := nil

    /*doc SemVer pre Pre-release status (i.e. `D` in `A.B.C-D.E`, `ALPHA`,
    `BETA` or `RC`).*/
    pre := nil
    
    //doc SemVer preNumber Pre-release version number (i.e. `E` in `A.B.C-D.E`).
    preNumber := nil

    /*doc SemVer originalSeq 
    The `Sequence` from which this `SemVer` was initialized.*/
    originalSeq := nil

    /*doc SemVer fromSeq(versionSeq) Init `SemVer` instance from the given
    `Sequence`.*/
    fromSeq := method(verSeq,
        if (verSeq isNil, Exception raise(IsNilError))
        res := self clone
        res originalSeq = verSeq
        spl := self _stripWord(verSeq) split("-")
        if(spl isEmpty or spl size > 2, Exception raise(NotRecognisedError)) 

        res _parseNormal(spl at(0))

        if(spl at(1) isNil not, res _parsePre(spl at(1)))
        res)

    # strips anything like "v", "V", "version" etc.
    _stripWord := method(seq,
        index := seq asLowercase findSeqs(
            list("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "alpha",
                "beta", "rc"))
        if (index isNil, Exception raise(NotRecognisedError))
        seq splitAt(index index) at(1))

    # Parse A.B.C
    _parseNormal := method(verSeq,
        spl := verSeq split(".")
        if(spl isEmpty or spl at(0) ?asNumber ?isNan or spl size > 3,
            Exception raise(NotRecognisedError)) 

        self major = spl at(0) asNumber
        self minor = spl at(1) ?asNumber
        self patch = spl at(2) ?asNumber)

    # Parse D.C
    _parsePre := method(verSeq,
        if(self patch isNil, Exception raise(IlligibleVersioningError))

        spl := verSeq split(".")
        if(spl isEmpty, Exception raise(NotRecognisedError)) 

        st := spl at(0) asUppercase
        legal := list("ALPHA", "BETA", "RC")
        if(legal contains(st) not, Exception raise(ParsePreError))

        self pre = st

        preNum := spl at(1) ?asNumber
        if(preNum ?isNan, Exception raise(IlligibleVersioningError))
        self preNumber = spl at(1) ?asNumber)

    /*doc SemVer nextVersion 
    Get next version from known numbers. For example, if the version is
    shortened to "v1.0" it will return version "v1.1".*/
    nextVersion := method(
        # we make a temporary clone of self to modify it and then init a new
        # `SemVer` from it. This way we get a `SemVer` with correct `originalSeq`
        tempVer := self clone

        if (self isPre and self preNumber) then (
           tempVer preNumber = tempVer preNumber + 1
        ) elseif (self isPre) then (
           tempVer pre = self _nextPre(tempVer pre)
       ) elseif (self patch isNil not) then (
           tempVer patch = tempVer patch + 1
       ) elseif (self minor isNil not) then (
           tempVer minor = tempVer minor + 1
       ) else (
           tempVer major = tempVer major + 1)

       return SemVer fromSeq(tempVer asSeq))

    _nextPre := method(word,
        if (word == "ALPHA") then (
            return "BETA"
        ) elseif (word == "BETA") then (
            return "RC"))

    /*doc SemVer highestIn(List)
    Get the highest version (covered by this version) in the provided `List`.*/
    highestIn := method(versions,
        if (versions isEmpty, return nil)

        if (self major isNil, return self _highestVersion(versions))

        result := self
        versions foreach(ver, 
            if (ver <= self and ver isPre == self isPre, 
                result = ver))

        result)

    _highestVersion := method(versions,
        result := versions at(0)

        versions foreach(ver,
            if (ver > result, result = ver))

        result)

    /*doc SemVer includes(SemVer)
    Returns boolean whether current `SemVer` includes the passed one.*/
    includes := method(ver,
        if (self isShortened not) then (
            return self == ver
        ) elseif (self minor isNil) then (
            return self major == ver major
        ) elseif (self patch isNil) then (
            return self major == ver major and(self minor == ver minor)
        ) elseif (self preNumber isNil) then (
            return self major == ver major and \
                self minor == ver minor and \
                    self pre == ver pre))

    //doc SemVer isShortened Returns a boolean whether the version is shortened.
    isShortened := method(
        self patch isNil or (self isPre and self preNumber isNil))

    /*doc SemVer isPre Returns `true` if the version is pre-release and `false`
    otherwise.*/
    isPre := method(self pre isNil not)

    //doc SemVer asSeq Returns sequence representation of a `SemVer`.
    asSeq := method(
        res := ""
        self major isNil ifFalse(res = res .. self major)
        self minor isNil ifFalse(res = res .. "." .. self minor)
        self patch isNil ifFalse(res = res .. "." .. self patch)
        self pre isNil ifFalse(res = res .. "-" .. self pre)
        self preNumber isNil ifFalse(res = res .. "." .. self preNumber)
        res asLowercase)

    == := method(right, self compare(right) == 0)
    != := method(right, self compare(right) != 0)
    >= := method(right, 
        res := self compare(right)
        res == 0 or res == 1)
    <= := method(right, 
        res := self compare(right)
        res == 0 or res == -1)
    > := method(right, self compare(right) == 1)
    < := method(right, self compare(right) == -1)

    compare := method(right,
        if (right type != self type, Exception raise(WrongTypeError))

        if (self major == right major and(self minor == right minor) and(
            self patch == right patch) and(self pre == right pre) and(
                self preNumber == right preNumber),
                return 0) 

        if (self major < right major) then (
            return -1
        ) elseif (self major > right major) then (
            return 1
        ) elseif (self minor < right minor) then (
            return -1
        ) elseif (self minor > right minor) then (
            return 1
        ) elseif (self patch < right patch) then (
            return -1
        ) elseif (self patch > right patch) then (
            return 1
        ) elseif (self isPre and right isPre not) then (
            return -1
        ) elseif (self isPre not and right isPre) then (
            return 1
        ) elseif (self _comparePre(right pre) == -1) then (
            return -1
        ) elseif (self _comparePre(right pre) == 1) then (
            return 1
        ) elseif (self preNumber < right preNumber) then (
            return -1
        ) elseif (self preNumber > right preNumber) then (
            return 1)

        Exception raise(UnreachableError))

    # compares only pre part of SemVer
    # returns -1 if this pre is less then the argument's one
    # returns 0 if they are equal
    # returns 1 if this pre is greater then the argument's one
    _comparePre := method(right,
        (self pre == right) ifTrue(return 0)

        if (self pre == "ALPHA") then (
            return -1
        ) elseif (self pre == "RC") then (
            return 1
        ) elseif (self pre == "BETA" and right == "ALPHA") then (
            return 1
        ) else (
            return -1)

        Exception raise(UnreachableError))

)

SemVer do (

    IsNilError := Error with("Version can not be initialized from 'nil'.")

    NotRecognisedError := Error with(
        "The sequence is not recognised as semantic version.")

    ParsePreError := Error with("The pre-release status is either 'alpha', " ..
        "'beta' or 'rc' and optinaly contains version number after '.' symbol.")

    IlligibleVersioningError := Error with("The version is illigible. " ..
        "Please, read the docs for rules.")

    UnreachableError := Error with("The code is supposed to be unreachable." ..
        "It's a bug if you see this message.")

    WrongTypeError := Error with("Wrong type used in operation.")

)
