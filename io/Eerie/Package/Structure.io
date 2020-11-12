//metadoc Structure category Package
//metadoc Structure description Directory structure of `Package`.
Structure := Object clone do (

    doRelativeFile("Structure/Manifest.io")
    doRelativeFile("Structure/PacksIo.io")

    //doc Structure root The root `Directory`.
    root := nil

    /*doc Structure bin
    The `bin` directory. `Directory` with binaries of the package.*/
    bin := method(self root directoryNamed("bin"))

    /*doc Structure binDest
    Get the `_bin` directory, where binaries of dependencies are installed.*/
    binDest := method(self root createSubdirectory("_bin"))

    /*doc Structure build
    Get object with `_build` directory structure.

    - `build root` - the `_build` root `Directory`
    - `build dll` - the output `Directory` for dynamic library the package
    represents
    - `build headers` - the `Directory` where all the headers of the package is
    installed
    - `build lib` - the output `Directory` for static library the package
    represents
    - `build objs` - the output `Directory for the compiled objects*/
    build := nil

    //doc Structure packs Get the `_packs` `Directory`.
    packs := method(self root createSubdirectory("_packs"))

    /*doc Structure source
    The `source` directory. The `Directory` with native (C) code.*/
    source := method(self root createSubdirectory("source"))

    /*doc Structure tmp
    Get `_tmp` `Directory`.*/
    tmp := method(self root createSubdirectory("_tmp"))

    //doc Structure buildio The `build.io` file.
    buildio := lazySlot(self root fileNamed("build.io"))

    //doc Structure manifest Get the `Package Manifest`.
    manifest := nil

    //doc Structure packsio Get the `Package PacksIo`.
    packsio := lazySlot(PacksIo with(self))

    /*doc Structure packRootFor(name)
    Get a directory for package name (`Sequence`) inside `packs` whether it's
    installed or not.*/ 
    packRootFor := method(name, self packs directoryNamed(name))

    /*doc Structure packFor(name, version)
    Get `Directory` for package inside `packs` for its name (`Sequence`) and
    version (`SemVer`).*/
    packFor := method(name, version,
        self packRootFor(name) directoryNamed(version asSeq))

    /*doc Structure with(rootPath) 
    Init `Structure` with the path to the root directory (`Sequence`).*/
    with := method(rootPath,
        klone := self clone
        klone root = Directory with(rootPath)
        klone build := BuildDir with(klone root)
        manifestFile := File with(
            rootPath .. "/#{Eerie manifestName}" interpolate) 
        klone manifest := Manifest with(manifestFile)

        klone)

    /*doc Structure isPackage(root)
    Returns boolean whether the `root` `Directory` is a `Package`.*/
    isPackage := method(root,
        ioDir := root directoryNamed("io")
        manifest := File with(
            root path .. "/" .. "#{Eerie manifestName}" interpolate)

        root exists and manifest exists and ioDir exists)

    /*doc Structure hasNativeCode 
    Returns `true` if the structure has native code and `false` otherwise.*/
    hasNativeCode := method(
        self source files isEmpty not or self source directories isEmpty not)

    /*doc Structure hasBinaries
    Returns `true` if `self bin` has files and `false` otherwise.*/
    hasBinaries := method(self bin exists and self bin files isEmpty not)

    /*doc Structure dllPath
    Get the path to the dynamic library this package represents.*/
    dllPath := method(self build dll path .. "/" .. self dllFileName)

    /*doc Structure dllFileName 
    Get the file name of the dynamic library provided by this package in the
    result of compilation with `lib` prefix.*/
    dllFileName := method("lib" .. self dllName .. "." .. Eerie dllExt)

    /*doc Structure dllName 
    Get the name of the dynamic library provided by this package in the result
    of compilation. Note, this is the name of the library, not the name of the
    dll file (i.e. without extension and `lib` prefix). Use `Package
    dllFileName` for the DLL file name.*/
    dllName := method("Io" .. self manifest name)

    /*doc Structure staticLibPath
    Get the path to the static library this package represents.*/
    staticLibPath := method(
        self build lib path .. "/" .. self staticLibFileName)

    /*doc Structure staticLibFileName 
    Get the file name of the static library provided by this package in the
    result of compilation.*/
    staticLibFileName := method("lib" .. self staticLibName .. ".a")

    /*doc Structure staticLibName 
    Get the name of the static library provided by this package in the result of
    compilation. Note, this is the name of the library, not the name of the dll
    file (i.e. the extension and without `lib` prefix). Use 
    `Structure staticLibFileName` for the static library file name.*/
    staticLibName := method("Io" .. self manifest name)

    BuildDir := Object clone do (
        
        parent := nil

        with := method(parent,
            klone := self clone
            klone parent = parent
            klone)

        root := method(self parent createSubdirectory("_build"))

        dll := method(self root createSubdirectory("dll"))

        headers := method(self root createSubdirectory("headers"))

        lib := method(self root createSubdirectory("lib"))

        objs := method(self root createSubdirectory("objs"))

    )

)
