# This module contains commands for compiler, static linker and dynamic linker

Command := Object clone do (
    asSeq := method(nil)
)

CompilerCommand := Command clone do (
    package := nil

    # the file this command should compile
    src ::= nil

    _depsManager := nil

    _defines := lazySlot(
        build := "BUILDING_#{self package name asUppercase}_ADDON" interpolate 
        
        result := if(Builder platform == "windows",
            list(
                "WIN32",
                "NDEBUG", 
                "IOBINDINGS", 
                "_CRT_SECURE_NO_DEPRECATE"),
            list("SANE_POPEN",
                "IOBINDINGS"))

        if (list("cygwin", "mingw") contains(Builder platform),
            result append(build))

        result)

    with := method(pkg, depsManager,
        klone := self clone
        klone package = pkg
        klone _depsManager = depsManager
        klone)

    addDefine := method(def, self _defines appendIfAbsent(def))

    asSeq := method(
        if (self src isNil, Exception raise(SrcNotSetError with("")))

        objName := self src name replaceSeq(".cpp", ".o") \
            replaceSeq(".c", ".o") \
                replaceSeq(".m", ".o")

        includes := self _depsManager _headerSearchPaths map(v, 
            "-I" .. v) join(" ")

        command := "#{self _cc} #{self _options} #{includes}" interpolate

        ("#{command} -c #{self _ccOutFlag}" ..
            "#{self package dir path}/_build/objs/#{objName} " ..
            "#{self package dir path}/source/#{self src name}") interpolate)

    _options := lazySlot(
        result := if(Builder platform == "windows",
            "-MD -Zi",
            "-Os -g -Wall -pipe -fno-strict-aliasing -fPIC")

        cFlags := System getEnvironmentVariable("CFLAGS") ifNilEval("")
        
        result .. cFlags .. " " .. self _defines map(d, "-D" .. d) join(" "))
)

CompilerCommandWinExt := Object clone do (
    _cc := method(System getEnvironmentVariable("CC") ifNilEval("cl -nologo"))
    _ccOutFlag := "-Fo"
)

CompilerCommandUnixExt := Object clone do (
    _cc := method(System getEnvironmentVariable("CC") ifNilEval("cc"))
    _ccOutFlag := "-o "
)

if (Builder platform == "windows", 
    CompilerCommand prependProto(CompilerCommandWinExt),
    CompilerCommand prependProto(CompilerCommandUnixExt)) 

# CompilerCommand error types
CompilerCommand do (
    SrcNotSetError := Eerie Error clone setErrorMsg(
        "Source file to compile doesn't set.")
)

StaticLinkerCommand := Command clone do (
    package := nil

    with := method(pkg,
        klone := self clone
        klone package = pkg
        klone)

    outputName := method("libIo" .. self package name ..  ".a")

    asSeq := method(
        path := self package dir path
        result := ("#{self _ar} #{self _arFlags}" ..
            "#{path}/_build/lib/#{self outputName} " ..
            "#{path}/_build/objs/*.o") interpolate

        if (self _ranlibSeq isEmpty, return result)
        
        result .. " && " .. self _ranlibSeq)

    _ranlibSeq := method(
        if (self _ranlib isNil, return "") 

        path := self package dir path
        "#{self _ranlib} #{path}/_build/lib/#{self outputName}" interpolate)
)

StaticLinkerCommandWinExt := Object clone do (
    _ar := "link -lib -nologo"
    _arFlags := "-out:"
    _ranlib := nil
)

StaticLinkerCommandUnixExt := Object clone do (
    _ar := method(
        System getEnvironmentVariable("AR") ifNilEval("ar"))
    _arFlags := "rcu "

    _ranlib := method(
        System getEnvironmentVariable("RANLIB") ifNilEval("ranlib"))
)

if (Builder platform == "windows",
    StaticLinkerCommand prependProto(StaticLinkerCommandWinExt),
    StaticLinkerCommand prependProto(StaticLinkerCommandUnixExt)) 
