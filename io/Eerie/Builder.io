//metadoc Builder category API
/*metadoc Builder description
Builder for native packages. This proto knows how to build a `Package` with
native code. 

Normally, you shouldn't use this directly. Use `Installer build` instead. But
here you'll find API you can use inside your `build.io` script as it's evaluated
in the context of `Builder` (i.e. it's its ancestor).*/

Builder := Object clone do (

    doRelativeFile("Builder/Command.io")
    doRelativeFile("Builder/DependencyManager.io")
    doRelativeFile("Builder/InitFileGenerator.io")
    
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

    # see `DynamicLinkerCommand`
    _dynLinkerCommand := nil

    //doc Builder with(Package) Always use this to initialize `Builder`.
    with := method(pkg, 
        klone := self clone
        klone package = pkg
        klone _initFileGenerator = InitFileGenerator with(pkg)
        klone _depsManager = DependencyManager with(pkg)
        klone _compilerCommand = CompilerCommand with(pkg, klone _depsManager)
        klone _staticLinkerCommand = StaticLinkerCommand with(pkg)
        klone _dynLinkerCommand = DynamicLinkerCommand with(pkg,
            klone _depsManager)
        klone)

    /*doc Builder build
    Build the package. You very rarely need this directly - use 
    `Installer build` instead.*/
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
        headers := Directory with(self package sourceDir path) \
        filesWithExtension(".h")

        if(headers size > 0,
            headers foreach(file,
                file copyToPath(
                    self package headersBuildDir path .. "/" .. file name))))

    _cFiles := method(
        sourceFolder := self package sourceDir
        files := sourceFolder filesWithExtension("cpp") appendSeq(
            sourceFolder filesWithExtension("c"))
        if(Eerie platform != "windows", 
            files appendSeq(sourceFolder filesWithExtension("m")))
        files select(f, f name beginsWithSeq("._") not))

    _compileFile := method(src,
        Eerie log("Compiling #{src name}")

        objName := src name replaceSeq(".cpp", ".o") \
            replaceSeq(".c", ".o") \
                replaceSeq(".m", ".o")

        obj := self package objsBuildDir fileNamed(objName)

        if(obj exists not or obj lastDataChangeDate < src lastDataChangeDate,
            Eerie sh(self _compilerCommand setSrc(src) asSeq)))

    _buildStaticLib := method(
        Eerie log("Linking #{self package staticLibFileName}")

        self staticLibBuildStarted

        Eerie sh(self _staticLinkerCommand asSeq))

    _buildDynLib := method(
        Eerie log("Linking #{self package dllFileName}")

        self dynLibBuildStarted

        # create DLL output dir if it doesn't exist
        self package dllBuildDir 

        libname := self package dllName

        Eerie sh(self _dynLinkerCommand asSeq)

        if (Eerie platform != "windows", return)

        Eerie log(
            "Removing manifest file #{self _dynLinkerCommand manifestPath}")
        
        File with(self _dynLinkerCommand manifestPath) remove)

)

# build.io API
Builder do (

    //doc Builder addDefine(Sequence) Add define macro to compiler command.
    addDefine := method(def, self _compilerCommand addDefine(def))

    /*doc Builder headerSearchPaths 
    Get the list of headers search paths. Don't modify it directly, use 
    `Builder appendHeaderSearchPath` instead.*/
    headerSearchPaths := method(self _depsManager headerSearchPaths)

    /*doc Builder appendHeaderSearchPath(Sequence) 
    Append header search path. If the path is relative, it's relative to the
    package's root directory.*/
    appendHeaderSearchPath := method(path, 
        self _depsManager appendHeaderSearchPath(path))

    /*doc Builder libSearchPaths
    Get the list of libraries search paths. Don't modify it directly, use 
    `Builder appendLibSearchPath` instead.*/
    libSearchPaths := method(self _depsManager libSearchPaths)

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
    Add optional library dependency. Returns `true` if the library was found and
    added and `false` otherwise.*/
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
    Callback called when the build process started. Feel free to redefine it
    inside your `build.io`.*/
    buildStarted := method()

    /*doc Builder staticLibBuildStarted
    Callback called when the linker started to build the static library. Feel
    free to redefine it inside your `build.io`.*/
    staticLibBuildStarted := method()

    /*doc Builder dynLibBuildStarted
    Callback called when linker started to build the dynamic library. Feel
    redefine to rewrite it inside your `build.io`*/
    dynLibBuildStarted := method()

    /*doc Builder buildFinished 
    Callback called when the build process finished. Feel free to redefine it
    inside your `build.io`.*/
    buildFinished := method()

)
