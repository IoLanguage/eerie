//metadoc Installer category API
/*metadoc Installer description 
This object is used to install and build package dependencies. Use 
`Installer with(package)` to initialize it.*/

Installer := Object clone do (

    /*doc Installer package
    The `Package` for which the `Installer` will install dependencies.*/
    package ::= nil

    //doc Installer with(package) Initializes installer with the given package.
    with := method(pkg, self clone setPackage(pkg))

    /*doc Installer install(dependency)
    Installs `dependency` (`Package`). 

    Returns `true` if the package installed successfully.*/
    install := method(dependency,
        self _checkPackageSet
        self _checkHasDep(dependency)

        pkgDestination := self _destination(dependency)
        if (pkgDestination exists, 
            Exception raise(DirectoryExistsError with(
                dependency name, pkgDestination path)))

        Logger log("📥 [[cyan bold;Installing [[reset;#{dependency name}", 
            "output")

        self _checkGitBranch(dependency)

        self build(dependency)

        pkgDestination createIfAbsent

        dependency dir copyTo(pkgDestination)

        self _installBinaries(dependency)

        self package appendPackage(Package with(pkgDestination))

        true)

    _checkPackageSet := method(
        if (self package isNil, Exception raise(PackageNotSetError clone)))

    # check whether `package` has dependency (i.e. in eerie.json) with
    # `dependency name`
    _checkHasDep := method(dependency,
        depConfig := self package configForDependencyName(dependency name)

        if (depConfig isNil,
            Exception raise(NoDependencyError with(
                self package name,
                dependency name))))

    # this is the directory inside `addonsDir` which represents the package and
    # contains its sources
    _destination := method(dependency,
        self package addonsDir directoryNamed(dependency name))

    # there are two scenarios for `branch` configuration:
    # 1. The user can specify branch per dependency in `addons`:
    # ...
    # "addons": [
    #     {
    #        ...
    #        "branch": "develop"
    #     }
    # ]
    # ...
    #
    # 2. The developer can specify main `"branch"` for the package.
    #
    # The first scenario has more priority, so we try to get the user specified
    # branch first and then if it's `nil` we check the developer's one.
    #
    # (we already sure here that the `package` has `dependency name`)
    _checkGitBranch := method(dependency,
        depConfig := self package configForDependencyName(dependency name)
        branch := depConfig at("branch")
        branch = branch ifNilEval(dependency config at("branch"))

        if (branch isNil, return)

        Eerie sh("git checkout #{branch}", false, self newer dir path))

    /*doc Installer build(Package) Compiles the `Package` if it has
    native code. Returns `true` if the package was compiled and `false`
    otherwise. Note, the return value doesn't mean whether the compilation was
    successful or not, it's just about whether it's went through the compilation
    process.

    To customize compilation you can modify `build.io` file at the root of your
    package. This file is evaluated in the context of `Builder` so you can treat
    it as an ancestor of `Builder`. If you want to link a library `foobar`, for
    example, your `build.io` file would look like:

    ```Io
    dependsOnLib("foobar")
    ```

    Look `Builder`'s documentation for more methods you can use in `build.io`.
    */
    build := method(dependency,
        self _checkPackageSet

        if(dependency hasNativeCode not, return false)

        dependency buildio create

        Logger log(
            "🔨 [[cyan bold;Building [[reset;#{dependency name}" ,
            "output")

        builder := Builder with(dependency)
        builder doFile(dependency buildio path)
        builder build

        true)

    # For global packages, creates symlinks (UNIX-like) or .cmd files (Windows).
    # This method is called only after the dependency is copied to destination
    # folder. It works in the dependency's destination folder.
    _installBinaries := method(dependency,
        self _checkPackageSet

        if (dependency hasBinaries not, return false)

        # this is the binaries directory (from where the binaries will be
        # installed), but at the destination
        # Note, here we consider that the dependency is already installed to
        # it's destination, so we can't use `dependency binDir` as the path has
        # changed
        binDir := self _destination(dependency) directoryNamed(
            dependency binDir name)
        binDir files foreach(f, if(Eerie isWindows, 
            self _createCmdForBin(f),
            self _createLinkForBin(f)))

        return true)

    # binaries will be installed in this directory
    _binInstallDir := method(
        self root directoryNamed(self package name) \
            directoryNamed(self destBinName))

    # This method is used on Windows to create .cmd file to be able to execute a
    # package binary as a normal command (i.e. `eerie` instead of
    # `io /path/to/eerie/bin`)
    _createCmdForBin := method(bin,
        cmd := self package destBinDir fileNamed(bin name .. ".cmd")
        cmd open setContents("io #{bin path} %*" interpolate) close)

    # We just create a link for binary on unix-like system
    _createLinkForBin := method(bin,
        # make sure it's executable
        Eerie sh("chmod u+x #{bin path}")
        # create the link
        link := self package destBinDir fileNamed(bin name)
        link exists ifFalse(Eerie sh("ln -s #{bin path} #{link path}"))
        link close)
)

# Errors
Installer do (

    //doc Installer PackageNotSetError
    PackageNotSetError := Eerie Error clone setErrorMsg("Package didn't set.")

    //doc Installer NoDependencyError
    NoDependencyError := Eerie Error clone setErrorMsg(
        "The package \"#{call evalArgAt(0)}\" has no dependency " .. 
        "\"#{call evalArgAt(1)}\" in #{Package manifestName}.")

    //doc Installer DirectoryExistsError
    DirectoryExistsError := Eerie Error clone setErrorMsg("Can't install " ..
        "the package #{call evalArgAt(0)}. The destination directory " ..
        "'#{call evalArgAt(1)}' already exists.")

    //doc Installer RootNotSetError
    RootNotSetError := Eerie Error clone setErrorMsg(
        "Package installer root directory didn't set.")

)
