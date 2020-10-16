//metadoc Builder category API
/*metadoc Builder description
Builder for native packages. This proto knows how to build a `Package` with
native code. 

Normally, you shouldn't use this directly. Use `Installer build` instead. But
here you'll find methods you can use inside your `build.io` script as it's
evaluated in the context of `Builder` (i.e. it's its ancestor).*/

Command

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
    _depsManager := nil

    # see `CompilerCommand`
    _compilerCommand := nil

    # see `StaticLinkerCommand`
    _staticLinkerCommand := nil

    //doc Builder with(Package) Always use this to initialize `Builder`.
    with := method(pkg, 
        klone := self clone
        klone package = pkg
        klone _initFileGenerator = InitFileGenerator with(pkg)
        klone _depsManager = DependencyManager with(pkg)
        klone _compilerCommand = CompilerCommand with(pkg, klone _depsManager)
        klone _staticLinkerCommand = StaticLinkerCommand with(pkg)
        klone)

    /*doc Builder build
    Build the package. You very rarely need this directly - use `Installer
    build` instead.*/
    build := method(
        if (package hasNativeCode not, 
            Eerie log("The package #{self package name} has no code to compile")
            return)

        self _depsManager checkMissing

        self buildStarted

        self _copyHeaders

        if (self shouldGenerateInit, self _initFileGenerator generate)

        self _cFiles foreach(src, self _compileFile(src))

        self _buildStaticLib

        self _buildDynLib

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

    _compileFile := method(src,
        Eerie log("Compiling #{src name}")

        objName := src name replaceSeq(".cpp", ".o") \
            replaceSeq(".c", ".o") \
                replaceSeq(".m", ".o")

        obj := self package dir \
            createSubdirectory("_build/objs") fileNamed(objName)

        if(obj exists not or obj lastDataChangeDate < src lastDataChangeDate,
            Eerie sh(self _compilerCommand setSrc(src) asSeq)))


    _buildStaticLib := method(
        Eerie log("Building #{self _staticLinkerCommand outputName}")

        self staticLibBuildStarted

        self package dir directoryNamed("_build/lib") createIfAbsent
        Eerie sh(self _staticLinkerCommand asSeq))

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
        links := self _depsManager _addons map(b, 
            "#{linkDirPathFlag}../#{b}/_build/dll" interpolate)

        links appendSeq(self _depsManager _addons map(v,
            "#{self linkLibFlag}Io#{v}#{self linkLibSuffix}" interpolate))

        if(platform == "windows",
            links appendSeq(self _depsManager _syslibs map(v, v .. ".lib")))

        if(platform != "darwin" and platform != "windows",
            links appendSeq(
                self _depsManager _addons map(v,
                    # TODO
                    "-Wl,--rpath -Wl,#{Eerie root}/activeEnv/addons/#{v}/_build/dll/" interpolate)))

        links appendSeq(
            self _depsManager _libSearchPaths map(v, linkDirPathFlag .. v))

        links appendSeq(self _depsManager _libs map(v,
            if(v at(0) asCharacter == "-", 
                v,
                linkLibFlag .. v .. linkLibSuffix)))

        links appendSeq(list(linkDirPathFlag .. (System installPrefix), 
            linkLibFlag .. "iovmall" .. linkLibSuffix,
            linkLibFlag .. "basekit" .. linkLibSuffix))

        links appendSeq(
            self _depsManager _frameworks map(v, "-framework " .. v))

        links appendSeq(self _depsManager _linkOptions)

        s := ""

        if(platform == "darwin",
            links append("-flat_namespace")
            # FIXME Eerie root /activeEnv/addons There's no such thing anymore
            s := " -install_name " .. (Eerie root) .. "/activeEnv/addons/" .. self package name .. "/_build/dll/" .. libname)

        linksJoined := links join(" ")

        cflags := System getEnvironmentVariable("CFLAGS") ifNilEval("")
        linkCommand := "#{linkdll} #{cflags} #{_dllCommand} #{s} #{linkOutFlag}#{self package dir path}/_build/dll/#{libname} #{self package dir path}/_build/objs/*.o #{linksJoined}" interpolate
        Eerie sh(linkCommand)

        self _embedManifest)

    _dllNameFor := method(s, "lib" .. s .. "." .. _dllSuffix)

    _dllSuffix := method(
        if(list("cygwin", "mingw", "windows") contains(platform), return "dll")
        if(platform == "darwin", return "dylib")
        "so")

    _dllCommand := method(
        if(platform == "darwin") then (
            return "-dynamiclib -single_module"
        ) elseif (platform == "windows") then (
            return "-dll -debug"
        ) else (
            return "-shared"))

    _embedManifest := method(
        if((platform == "windows") not, return)
        dllFilePath := self package dir path .. 
            "/_build/dll/" .. _dllNameFor("Io" .. self package name)
        manifestPath := dllFilePath .. ".manifest"
        Eerie sh("mt.exe -manifest " .. manifestPath ..
            " -outputresource:" .. dllFilePath)
        Eerie log("Removing manifest file #{manifestPath}")
        File with(self package dir path .. "/" .. manifestPath) remove)
)

# build.io API
Builder do (
    //doc Builder addDefine(Sequence) Add define macro to compiler command.
    addDefine := method(def, self _compilerCommand addDefine(def))

    /*doc Builder appendHeaderSearchPath(Sequence) 
    Append header search path. If the path is relative, it's relative to the
    package's root directory.*/
    appendHeaderSearchPath := method(path, 
        self _depsManager appendHeaderSearchPath(path))

    /*doc Builder appendLibSearchPath(Sequence) 
    Append library search path. If the path is relative, it's relative to the
    package's root directory.*/
    appendLibSearchPath := method(path,
        self _depsManager appendLibSearchPath(path))

    /*doc Builder dependsOnHeader(Sequence)
    Add header dependency. The value should include extension (i.e.
    `header.h`).*/
    dependsOnHeader := method(header, self _depsManager dependsOnHeader(header))

    /*doc Builder dependsOnLib(Sequence)
    Add library dependency. The value should not contain `lib` prefix and
    extension.*/
    dependsOnLib := method(name, self _depsManager dependsOnLib(name))

    /*doc Builder dependsOnSysLib(Sequence) 
    Add system library dependency. Applicable to Windows only.*/
    dependsOnSysLib := method(name, self _depsManager dependsOnSysLib(name))

    /*doc Builder optionallyDependsOnLib(Sequence)
    Add optional library dependency.*/
    optionallyDependsOnLib := method(name, 
        self _depsManager optionallyDependsOnLib(name))

    /*doc Builder dependsOnFramework(Sequence)
    Add framework dependency. Applicable only to macOS.*/
    dependsOnFramework := method(name, 
        self _depsManager dependsOnFramework(name))

    /*doc Builder optionallyDependsOnFramework(Sequence) 
    Add optional framework dependency. Applicable only to macOS.*/
    optionallyDependsOnFramework := method(name, 
        self _depsManager optionallyDependsOnFramework(name))

    /*doc Builder dependsOnFrameworkOrLib(Sequence, Sequence) 
    Add either framework (the first argument) or library (the second argument)
    dependency. First it tries the framework and if it's not found the libray
    will be added to dependencies.*/
    dependsOnFrameworkOrLib := method(fw, lib, 
        self _depsManager dependsOnFrameworkOrLib(fw, lib))

    //doc Builder dependsOnLinkOption(Sequence) Add linker option dependency.
    dependsOnLinkOption := method(opt, 
        self _depsManager dependsOnLinkOption(opt))

    /*doc Builder buildStarted
    Callback called when the build process started. Feel free to rewrite it
    inside your `build.io`.*/
    buildStarted := method()

    /*doc Builder staticLibBuildStarted
    Callback called when the linker started to build the static library. Feel
    free to rewrite it inside your `build.io`.*/
    staticLibBuildStarted := method()

    /*doc Builder dynLibBuildStarted
    Callback called when linker started to build the dynamic library. Feel free
    to rewrite it inside your `build.io`*/
    dynLibBuildStarted := method()

    /*doc Builder buildFinished 
    Callback called when the build process finished. Feel free to rewrite it
    inside your `build.io`.*/
    buildFinished := method()
)

BuilderWindows := Object clone do (
    linkdll := "link -link -nologo"
    linkDirPathFlag := "-libpath:"
    linkLibFlag := ""
    linkOutFlag := "-out:"
    linkLibSuffix := ".lib"
)

BuilderUnix := Object clone do (
    linkdll := method(
        System getEnvironmentVariable("CC") ifNilEval("cc"))
    linkDirPathFlag := "-L"
    linkLibFlag := "-l"
    linkLibSuffix := ""
    linkOutFlag := "-o "
    linkLibSuffix := ""
)

if (Builder platform == "windows",
    Builder prependProto(BuilderWindows),
    Builder prependProto(BuilderUnix)) 
