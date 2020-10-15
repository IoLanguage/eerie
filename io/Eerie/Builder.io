//metadoc Builder category API
/*metadoc Builder description
Builder for native packages. This proto knows how to build a `Package` with
native code. 

Normally, you shouldn't use this directly. Use `Installer build` instead. But
here you'll find methods you can use inside your `build.io` script as it's
evaluated in the context of `Builder` (i.e. it's its ancestor).*/

Builder := Object clone do (
    //doc Builder platform Get the platform name (`Sequence`) as lowercase.
    platform := System platform split at(0) asLowercase

    /*doc Builder shouldGenerateInit Whether `Builder` should generate
    IoAddonNameInit.c file for your package. Default to `true`.*/
    shouldGenerateInit ::= true

    //doc Builder package Get the `Package` the `Builder` will build.
    package := nil

    # see `InitFileGenerator`
    _initFileGenerator := nil

    # see `Deps`
    _depends := nil

    # see `CompilerCommand`
    _compilerCommand := nil

    //doc Builder with(Package) Always use this to initialize `Builder`.
    with := method(pkg, 
        klone := self clone
        klone package = pkg
        klone _initFileGenerator = InitFileGenerator with(pkg)
        klone _depends = Deps with(pkg)
        klone _compilerCommand = CompilerCommand with(pkg, klone _depends)
        klone)

    //doc Builder addDefine(Sequence) Add define macro to compiler command.
    addDefine := method(def, self _compilerCommand addDefine(def))

    /*doc Builder appendHeaderSearchPath(Sequence) Append header search path. If
    the path is relative, it's relative to the package's root directory.*/
    appendHeaderSearchPath := method(path, 
        self _depends appendHeaderSearchPath(path))

    /*doc Builder appendLibSearchPath(Sequence) Append library search path. If
    the path is relative, it's relative to the package's root directory.*/
    appendLibSearchPath := method(path, self _depends appendLibSearchPath(path))

    /*doc Builder dependsOnHeader(Sequence) Add header dependency. The value
    should include extension (i.e. `header.h`).*/
    dependsOnHeader := method(header, self _depends dependsOnHeader(header))

    /*doc Builder dependsOnLib(Sequence) Add library dependency. The value
    should not contain `lib` prefix and extension.*/
    dependsOnLib := method(name, self _depends dependsOnLib(name))

    /*doc Builder dependsOnSysLib(Sequence) Add system library dependency.
    Applicable on Windows only.*/
    dependsOnSysLib := method(name, self _depends dependsOnSysLib(name))

    /*doc Builder optionallyDependsOnLib(Sequence) Add optional library
    dependency.*/
    optionallyDependsOnLib := method(name, 
        self _depends optionallyDependsOnLib(name))

    /*doc Builder dependsOnFramework(Sequence) Add framework dependency.
    Applicable only on macOS.*/
    dependsOnFramework := method(name, self _depends dependsOnFramework(name))

    /*doc Builder optionallyDependsOnFramework(Sequence) Add optional framework
    dependency. Applicable only on macOS.*/
    optionallyDependsOnFramework := method(name, 
        self _depends optionallyDependsOnFramework(name))

    /*doc Builder dependsOnFrameworkOrLib(Sequence, Sequence) Add either
    framework (the first argument) or library (the second argument) dependency.
    First it tries the framework and if it's not found the libray will be added
    to dependencies.*/
    dependsOnFrameworkOrLib := method(fw, lib, 
        self _depends dependsOnFrameworkOrLib(fw, lib))

    //doc Builder dependsOnLinkOption(Sequence) Add linker option dependency.
    dependsOnLinkOption := method(opt, self _depends dependsOnLinkOption(opt))

    /*doc Builder buildStarted Callback called when the build process started.
    Feel free to rewrite it inside your `build.io`.*/
    buildStarted := method()

    /*doc Builder staticLibBuildStarted Callback called when the linker started
    to build the static library. Feel free to rewrite it inside your
    `build.io`.*/
    staticLibBuildStarted := method()

    /*doc Builder dynLibBuildStarted Callback called when linker started to
    build the dynamic library. Feel free to rewrite it inside your `build.io`*/
    dynLibBuildStarted := method()

    /*doc Builder buildFinished Callback called when the build process finished.
    Feel free to rewrite it inside your `build.io`.*/
    buildFinished := method()

    _systemCall := method(cmd,
        result := Eerie sh(cmd, true)
        if(result != 0, 
            Exception raise(SystemCommandError with(cmd, result))))

    /*doc Builder build Build the package. You very rarely need this directly -
    use `Installer build` instead.*/
    build := method(
        if (package hasNativeCode not, 
            Eerie log("The package #{self package name} has no code to compile")
            return)

        self _depends checkMissing

        self buildStarted

        self _copyHeaders

        if (self shouldGenerateInit, self _initFileGenerator generate)

        self _cFiles foreach(src, self _compileFile(src))

        self _buildStaticLib
        self _buildDynLib
        self _embedManifest
        self buildFinished)

    # copy (install) headers into "_build/headers/"
    _copyHeaders := method(
        self package dir directoryNamed("_build/headers") createIfAbsent
        headers := Directory with(
            Path with(self package dir path, "source")) filesWithExtension(".h")

        if(headers size > 0,
            destinationPath := Path with(
                self package dir path, "_build/headers")
            headers foreach(file,
                file copyToPath(destinationPath .. "/" .. file name))))

    _cFiles := method(
        sourceFolder := self package sourceDir
        files := sourceFolder filesWithExtension("cpp") appendSeq(
            sourceFolder filesWithExtension("c"))
        if(platform != "windows", 
            files appendSeq(sourceFolder filesWithExtension("m")))
        files select(f, f name beginsWithSeq("._") not))

    _compileFile := method(src, options,
        Eerie log("Compiling #{src name}")

        objName := src name replaceSeq(".cpp", ".o") \
            replaceSeq(".c", ".o") \
                replaceSeq(".m", ".o")

        objFile := self package dir \
            createSubdirectory("_build/objs") fileNamed(objName)

            if(objFile exists not or(
                objFile lastDataChangeDate < src lastDataChangeDate),
                self _systemCall(self _compilerCommand forFile(src))))


    _buildStaticLib := method(
        staticLibName := "libIo" .. self package name ..  ".a"

        Eerie log("Building #{staticLibName}")

        self staticLibBuildStarted
        
        self package dir directoryNamed("_build/lib") createIfAbsent
        path := self package dir path
        self _systemCall("#{ar} #{arFlags}#{path}/_build/lib/#{staticLibName} #{path}/_build/objs/*.o" \
            interpolate)
        if(ranlib != nil,
            self _systemCall("#{ranlib} #{path}/_build/lib/#{staticLibName}" interpolate)))

    _dllCommand := method(
        if(platform == "darwin",
            "-dynamiclib -single_module"
            ,
            if (platform == "windows",
                "-dll -debug"
                ,
                "-shared")))

    _buildDynLib := method(
        libname := self _dllNameFor("Io" .. self package name)

        Eerie log("Building #{libname}")

        self dynLibBuildStarted

        self package dir directoryNamed("_build/dll") createIfAbsent

        # FIXME this should be `package dir with("_addons")` and `_build/dll`
        # inside of those addons. But the path, most probably, should be
        # absolute or better it should be relative to `package dir`
        # 
        # we should rethink this from the position of Eerie infra
        # we have dependencies list inside `eerie.json` and we know, that they
        # are inside _addons directory, so we know the path to the dll
        # BUT specifying package dependencies here is not safe, because we
        # don't guarantee it's installed. So we should consider that all the
        # addons we need already installed inside _addons directory and disallow
        # user to specify addons dependencies inside `build.io`... But it turns
        # out so is for headers and libraries.
        links := self _depends _addons map(b, 
            "#{linkDirPathFlag}../#{b}/_build/dll" interpolate)

        links appendSeq(self _depends _addons map(v,
            "#{self linkLibFlag}Io#{v}#{self linkLibSuffix}" interpolate))

        if(platform == "windows",
            links appendSeq(self _depends _syslibs map(v, v .. ".lib")))

        if(platform != "darwin" and platform != "windows",
            links appendSeq(
                self _depends _addons map(v,
                    # TODO
                    "-Wl,--rpath -Wl,#{Eerie root}/activeEnv/addons/#{v}/_build/dll/" interpolate)))

        links appendSeq(self _depends _libSearchPaths map(v, linkDirPathFlag .. v))

        links appendSeq(self _depends _libs map(v,
            if(v at(0) asCharacter == "-", 
                v,
                linkLibFlag .. v .. linkLibSuffix)))

        links appendSeq(list(linkDirPathFlag .. (System installPrefix), 
            linkLibFlag .. "iovmall" .. linkLibSuffix,
            linkLibFlag .. "basekit" .. linkLibSuffix))

        links appendSeq(self _depends _frameworks map(v, "-framework " .. v))

        links appendSeq(self _depends _linkOptions)

        s := ""

        if(platform == "darwin",
            links append("-flat_namespace")
            # FIXME Eerie root /activeEnv/addons There's no such thing anymore
            s := " -install_name " .. (Eerie root) .. "/activeEnv/addons/" .. self package name .. "/_build/dll/" .. libname)

        linksJoined := links join(" ")

        cflags := System getEnvironmentVariable("CFLAGS") ifNilEval("")
        linkCommand := "#{linkdll} #{cflags} #{_dllCommand} #{s} #{linkOutFlag}#{self package dir path}/_build/dll/#{libname} #{self package dir path}/_build/objs/*.o #{linksJoined}" interpolate
        self _systemCall(linkCommand))

    _dllNameFor := method(s, "lib" .. s .. "." .. _dllSuffix)

    _dllSuffix := method(
        if(list("cygwin", "mingw", "windows") contains(platform), return "dll")
        if(platform == "darwin", return "dylib")
        "so")

    _embedManifest := method(
        if((platform == "windows") not, return)
        dllFilePath := self package dir path .. "/_build/dll/" .. _dllNameFor("Io" .. self package name)
        manifestFilePath := dllFilePath .. ".manifest"
        self _systemCall("mt.exe -manifest " .. manifestFilePath .. \
            " -outputresource:" .. dllFilePath)
        Eerie log("Removing manifest file #{manifestFilePath}")
        File with(self package dir path .. "/" .. manifestFilePath) remove)
)

Deps := Object clone do (
    package := nil

    _headers := list()
    
    _headerSearchPaths := list(".")

    _searchPrefixes := list(
        System installPrefix,
        "/opt/local",
        "/usr",
        "/usr/local",
        "/usr/pkg",
        "/sw",
        "/usr/X11R6",
        "/mingw"
    )

    _libSearchPaths := list()

    _frameworkSearchPaths := list(
        "/System/Library/Frameworks",
        "/Library/Frameworks",
        "~/Library/Frameworks" stringByExpandingTilde
    )

    _libs := list()
    
    _frameworks := list()
    
    _syslibs := list()
    
    _linkOptions := list()

    _addons := list()

    init := method(
        self _searchPrefixes foreach(prefix,
            self appendHeaderSearchPath(prefix .. "/include"))

        self appendHeaderSearchPath(
            Path with(System installPrefix, "include", "io"))

        self _searchPrefixes foreach(prefix, 
            self appendLibSearchPath(prefix .. "/lib")))

    with := method(pkg, 
        klone := self clone
        klone package := pkg
        klone)

    appendHeaderSearchPath := method(path, 
        dir := self _dirForPath(path)
        if(dir exists, 
            self _headerSearchPaths appendIfAbsent(dir path)))

    appendLibSearchPath := method(path, 
        dir := self _dirForPath(path)
        if(dir exists,
            self _libSearchPaths appendIfAbsent(dir path)))

    # returns directory relative to package's directory if path relative and
    # just a directory if path is absolute
    _dirForPath := method(path,
        if (self _isPathAbsolute(path),
            Directory with(path),
            self package dir directoryNamed(path)))

    # whether the path is absolute
    _isPathAbsolute := method(path,
        if (Builder platform == "windows",
            path containsSeq(":\\") or path containsSeq(":/"),
            path beginsWithSeq("/")))

    dependsOnBinding := method(v, self _addons appendIfAbsent(v))

    dependsOnHeader := method(v, self _headers appendIfAbsent(v))

    dependsOnLib := method(v,
        self _libs contains(v) ifFalse(
            pkgLibs := self _pkgConfigLibs(v)
            if(pkgLibs isEmpty,
                self _libs appendIfAbsent(v),
                pkgLibs map(l, self _libs appendIfAbsent(l)))
            self _searchPrefixes appendIfAbsent(v)
            self _pkgConfigCFlags(v) select(containsSeq("/")) foreach(p,
                self appendHeaderSearchPath(p))))

    _pkgConfigLibs := method(pkg,
        self _pkgConfig(pkg, "--libs") splitNoEmpties(linkLibFlag) map(strip))

    _pkgConfigCFlags := method(pkg,
        self _pkgConfig(pkg, "--cflags") splitNoEmpties("-I") map(strip))

    _pkgConfig := method(pkg, flags,
        (Builder platform == "windows") ifTrue(return "")

        date := Date now asNumber asHex
        resFile := (self package dir path) .. "/_build/_pkg_config" .. date
        # System runCommand (Eerie sh) doesn't allow pipes (?), 
        # so here we use System system instead
        statusCode := System system(
            "pkg-config #{pkg} #{flags} --silence-errors > #{resFile}" \
                interpolate)

        if(statusCode == 0) then (
            resFile := File with(resFile) openForReading
            flags := resFile contents asMutable strip
            resFile close remove
            return flags
        ) else (
            return ""))

    dependsOnSysLib := method(v, self _syslibs appendIfAbsent(v))

    optionallyDependsOnLib := method(v, 
        a := self _pathForLib(v) != nil
        if(a, self dependsOnLib(v))
        a)

    _pathForLib := method(name,
        name containsSeq("/") ifTrue(return(name))
        libNames := list("." .. Builder _dllSuffix, ".a", ".lib") map(suffix, 
            "lib" .. name .. suffix)
        self _libSearchPaths detect(path,
            libDirectory := Directory with(path)
            libNames detect(libName, libDirectory fileNamed(libName) exists)))

    dependsOnFramework := method(v, self _frameworks appendIfAbsent(v))

    optionallyDependsOnFramework := method(v, 
        a := self _pathForFramework(v) != nil
        if(a, self dependsOnFramework(v))
        a)

    _pathForFramework := method(name,
        frameworkname := name .. ".framework"
        self _frameworkSearchPaths detect(path,
            Directory with(path .. "/" .. frameworkname) exists))

    dependsOnFrameworkOrLib := method(v, w,
        path := self _pathForFramework(v)
        if(path != nil) then (
            self dependsOnFramework(v)
            self appendHeaderSearchPath(path .. "/" .. v .. ".framework/Headers")
        ) else (
            self dependsOnLib(w)))

    dependsOnLinkOption := method(v, 
        self _linkOptions appendIfAbsent(v))

    # actually this will never be raise an exception, because we check the
    # existence of a path when we use append methods
    checkMissing := method(
        missing := self _missingHeaders
        if (missing isEmpty not,
            Exception raise(MissingHeadersError with(missing)))

        missing := self _missingLibs
        if (missing isEmpty not,
            Exception raise(MissingLibsError with(missing)))

        missing := self _missingFrameworks
        if (missing isEmpty not,
            Exception raise(MissingFrameworksError with(missing))))

    _missingHeaders := method(
        self _headers select(h, self _pathForHeader(p) isNil))

    _pathForHeader := method(name,
        self _headerSearchPaths detect(path,
            File with(path .. "/" .. name) exists))

    _missingLibs := method(self _libs select(p, self _pathForLib(p) isNil))

    _missingFrameworks := method(
        self _frameworks select(p, self _pathForFramework(p) isNil))
)

# Deps error types
Deps do (
    MissingHeadersError := Eerie Error clone setErrorMsg(
        """Header(s) #{call evalArgAt(0) join(", ")} not found.""")

    MissingLibsError := Eerie Error clone setErrorMsg(
        """Library(s) #{call evalArgAt(0) join(", ")} not found.""")

    MissingFrameworksError := Eerie Error clone setErrorMsg(
        """Framework(s) #{call evalArgAt(0) join(", ")} not found.""")
)

CompilerCommand := Object clone do (
    if (Builder platform == "windows",
        _cc := method(
            System getEnvironmentVariable("CC") ifNilEval("cl -nologo"))
        _ccOutFlag := "-Fo",

        _cc := method(
            System getEnvironmentVariable("CC") ifNilEval("cc"))
        _ccOutFlag := "-o ")

    package := nil

    _depends := nil

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

    with := method(pkg, deps,
        klone := self clone
        klone package = pkg
        klone _depends = deps
        klone)

    addDefine := method(def, self _defines appendIfAbsent(def))

    forFile := method(src,
        objName := src name replaceSeq(".cpp", ".o") \
            replaceSeq(".c", ".o") \
                replaceSeq(".m", ".o")

        includes := self _depends _headerSearchPaths map(v, "-I" .. v) join(" ")

        command := "#{self _cc} #{self _options} #{includes}" interpolate

        ("#{command} -c #{self _ccOutFlag}" ..
            "#{self package dir path}/_build/objs/#{objName} " ..
            "#{self package dir path}/source/#{src name}") interpolate)

    _options := lazySlot(
        result := if(Builder platform == "windows",
            "-MD -Zi",
            "-Os -g -Wall -pipe -fno-strict-aliasing -fPIC")

        cFlags := System getEnvironmentVariable("CFLAGS") ifNilEval("")
        
        result .. cFlags .. " " .. self _defines map(d, "-D" .. d) join(" "))
)

# Generates IoAddonNameInit.c file which contains code for initialization of the
# protos defined by the sources
InitFileGenerator := Object clone do (
    package := nil

    # the output file
    output := lazySlot(
        path := "source/Io#{self package name}Init.c" interpolate
        self package dir fileNamed(path))

    # directory with Io code
    ioCodeDir := method(self package dir directoryNamed("io"))

    # io files inside `io` directory
    # FIXME this should be `recursiveFileOfTypes(list("io"))`, but the generated
    # code may need to be changed too
    ioFiles := method(self ioCodeDir filesWithExtension("io"))
    
    # whether the compiled package should embed io code into the library
    embedIoCode ::= false

    # the initializer
    with := method(pkg, 
        klone := self clone
        klone package = pkg
        klone)

    # generates the file
    generate := method(
        Eerie log("Generating #{self output path}")

        self output remove create open

        self _writeHead

        ioCFiles := self _ioCFiles

        extraFiles := self _extraFiles

        self _writeDeclarations(ioCFiles, extraFiles)

        if (Builder platform == "windows",
            self output write("__declspec(dllexport)\n"))

        self _writeInitFunction(ioCFiles, extraFiles)
        self output close)

    _writeHead := method(
        self output write("""|
// This file is generated automatically. If you want to customize it, you should
// add setShouldGenerateInit(false) to the build.io, otherwise it will be
// rewritten on the next build.
//
// The slot setting order is not guaranteed to be alphabetical. If you want a
// slot to be set before another slot you can add a comment line like:
//
// docDependsOn("SlotName")
//
// This way the slot "SlotName" will be set before the current slot.
|
#include "IoState.h"
#include "IoObject.h" 
            """ fixMultiline, "\n\n"))

    # Get files like IoName.c
    _ioCFiles := method(
        sources := self package sourceDir files

        files := sources select(name beginsWithSeq("Io")) \
            select(f, f name endsWithSeq(".c") or f name endsWithSeq(".cpp")) \
                select(name containsSeq("Init") not) \
                    select(name containsSeq("_") not)

        # sort slot definitions considering docDependsOn
        sorted := files clone

        files foreach(file,
            if (depName := file open \
                    readLines detect(containsSeq("docDependsOn")),

                file close

                depFileName := \
                    "Io" .. depName afterSeq("(\"") beforeSeq("\")") .. ".c"
                depFile := sorted detect(name == depFileName)
                sorted remove(file)
                sorted insertAfter(file, depFile)))

        sorted)

    # Get files like IoName_doing.c
    _extraFiles := method(
        package sourceDir files \
            select(name beginsWithSeq("Io")) \
                select(name endsWithSeq(".c")) \
                    select(name containsSeq("Init") not) \
                        select(name containsSeq("_")))

    _writeDeclarations := method(sources, extras,
        sources foreach(f,
            self output write(
                "IoObject *#{f baseName}_proto(void *state);\n" interpolate))

        extras foreach(f,
            self output write(
                "void #{f baseName}Init(void *context);\n" interpolate)))

    _writeInitFunction := method(sources, extras,
        self output write(
            "\nvoid #{self output baseName}(IoObject *context)" interpolate)

        self output write(" {\n")

        if(sources isEmpty not,
            self output write(
                "\tIoState *self = IoObject_state((IoObject *)context);\n\n"))

        sources foreach(f,
            protoName := f baseName asMutable removePrefix("Io")
            self output write("\tIoObject_setSlot_to_(context, SIOSYMBOL(\"" ..\
                "#{protoName}\"), #{f baseName}_proto(self));\n\n" interpolate))

        extras foreach(f,
            self output write("\t#{f baseName}Init(context);\n" interpolate))

        if(self ioCodeDir and self embedIoCode,
            self ioFiles foreach(f, self output write(_codeForIoFile(f))))

        self output write("}\n"))

    _codeForIoFile := method(file,
        code := Sequence clone
        if (file size < 1, return code)

        code appendSeq("\t{\n\t\tchar *s = ")
        code appendSeq(file contents splitNoEmpties("\n") map(line,
            "\"#{line escape}\\n\"" interpolate) join("\n\t\t"))
        code appendSeq(
            ";\n\t\tIoState_on_doCString_withLabel_(self, context, s, \"" ..
                "#{file name}\");\n" interpolate)
        code appendSeq("\t}\n\n"))

    # better indentation for multiline strings
    Sequence fixMultiline := method(
        self splitNoEmpties("\n") map(split("|") last) join("\n") strip)
)

BuilderWindows := Object clone do (
    linkdll := "link -link -nologo"
    linkDirPathFlag := "-libpath:"
    linkLibFlag := ""
    linkOutFlag := "-out:"
    linkLibSuffix := ".lib"
    ar := "link -lib -nologo"
    arFlags := "-out:"
    ranlib := nil
)

BuilderUnix := Object clone do (
    linkdll := method(
        System getEnvironmentVariable("CC") ifNilEval("cc"))
    linkDirPathFlag := "-L"
    linkLibFlag := "-l"
    linkLibSuffix := ""
    linkOutFlag := "-o "
    linkLibSuffix := ""

    ar := method(
        System getEnvironmentVariable("AR") ifNilEval("ar"))
    arFlags := "rcu "

    ranlib := method(
        System getEnvironmentVariable("RANLIB") ifNilEval("ranlib"))
)

if (Builder platform == "windows",
    Builder prependProto(BuilderWindows),
    Builder prependProto(BuilderUnix)) 

# Error types
Builder do (
    //doc Builder SystemCommandError
    SystemCommandError := Eerie Error clone setErrorMsg(
        "Command '#{call evalArgAt(0)}' exited with status code " .. 
        "#{call evalArgAt(1)}")
)
