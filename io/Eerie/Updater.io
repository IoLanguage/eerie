//metadoc Updater category API
/*metadoc Updater description 
This proto is responsible for package updates. Notice, `Updater` updates only
locally (i.e. from a local directory). For downloading an updated package before
using `Updater` see [[Downloader]].*/

Updater := Object clone do (

    /*doc Updater package 
    The `Package` dependencies of which the updater should update.*/
    package := nil
    
    /*doc Updater newer 
    An update (`Package`) for some dependency of `Updater package`.*/
    newer := nil

    //doc Updater version `SemVer` to which `package` should be updated.
    version := nil

    # The `Package`, which the updater should update.
    # _targetPackage := lazySlot(self package packageNamed(self newer name))

    /*doc Updater with(target, newer, version)
    Initializer, where:
    - `target` - the `Package`, which updater should update
    - `newer` - an updated version of the `target`
    - `version` - `SemVer` to which `target` should be updated*/
    with := method(package, newer, version,
        klone := self clone
        klone package = package
        klone newer = newer
        klone version = version
        klone)

    /*doc Updater update 
    Install update.*/
    update := method(
        # self package checkHasDep(self newer name)
        self _checkSame
        self _checkHasVersions

        ver := self newer highestVersionFor(self version)

        self _logUpdate(ver)
        self package runHook("beforeUpdate")
        self _checkGitBranch
        self _checkGitTag(ver)
        self package remove
        self _installNew
        self package runHook("afterUpdate")

        Logger log(
            "☑  [[magenta bold;#{self newer name}[[reset; is " ..
            "[[magenta bold;#{version originalSeq}[[reset; now",
            "output"))

    _checkSame := method(
        if (self package name != self newer name, 
            Exception raise(
                DifferentPackageError with(
                    self package name, self newer name))))

    _checkHasVersions := method(
        if (self newer versions isEmpty,
            Exception raise(NoVersionsError with(self newer name))))

    _logUpdate := method(version,
        if (version > self package version) then (
            Logger log("⬆ [[cyan bold;Updating [[reset;" ..
                "#{self _targetPackage name} " ..
                "from [[magenta bold;" ..
                "v#{self _targetPackage version asSeq}[[reset; " ..
                "to [[magenta bold;v#{version asSeq}", "output")
        ) elseif (version < self package version) then (
            Logger log(
                "⬇ [[cyan bold;Downgrading [[reset;" .. 
                "#{self _targetPackage name} " ..
                "from v#{self _targetPackage version asSeq} " ..
                "to v#{version asSeq}", "output")
        ) else (
            Logger log(
                "☑  #{self _targetPackage name} " .. 
                "v#{self _targetPackage version asSeq} " ..
                "is already updated", "output")))

    _checkGitBranch := method(
        if (self newer branch isNil, return)
        Eerie sh("git checkout #{self newer branch}", 
            false, 
            self newer dir path))

    _checkGitTag := method(version,
        Eerie sh("git checkout tags/#{version originalSeq}", 
            false,
            self newer dir path))

    # installs the `newer` package
    _installNew := method(
        installer := Installer with(
            self newer,
            self package dir path)
        installer install)

)

# Updater error types
Updater do (

    //doc Updater DifferentPackageError
    DifferentPackageError := Eerie Error clone setErrorMsg(
        "Can't update package '#{call evalArgAt(0)}' " .. 
        "with package '#{call evalArgAt(1)}'")

    //doc Updater NoVersionsError
    NoVersionsError := Eerie Error clone setErrorMsg(
        "The package '#{call evalArgAt(0)}' has no tagged versions.")

    //doc Updater NotInstalledError
    NotInstalledError := Eerie Error clone setErrorMsg(
        "The dependency '#{call evalArgAt(0)}' is not installed.")

)
