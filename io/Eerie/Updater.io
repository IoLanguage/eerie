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

    # The `Package`, which the updater should update.
    _targetPackage := lazySlot(self package packageNamed(self newer name))

    /*doc Updater with(package, newer)
    Initializer, where:
    - package - the `Package` dependencies of which the updater should update
    - newer - a new version of a `package` dependency*/
    with := method(package, newer,
        klone := self clone
        klone package = package
        klone newer = newer
        klone)

    /*doc Updater update 
    Install update.*/
    update := method(
        self package checkHasDep(self newer name)
        self _checkInstalled
        self _checkHasVersions

        version := self newer highestVersionFor(self _targetVersion)

        self _logUpdate(version)
        self _checkGitBranch(self newer name)
        self _checkGitTag(version)
        self _removeOld
        self _installNew

        Logger log(
            "☑  [[magenta bold;#{self newer name}[[reset; is " ..
            "[[magenta bold;#{version originalSeq}[[reset; now",
            "output"))

    # check whether `package` is installed
    _checkInstalled := method(
        if (self _targetPackage isNil, 
            Exception raise(NotInstalledError with(self newer name))))

    _checkHasVersions := method(
        if (self newer versions isEmpty,
            Exception raise(NoVersionsError with(self newer name))))

    # the version, to which the dependency will be updated
    _targetVersion := lazySlot(
        addons := self package config at("addons")
        dep := addons detect(at("name") == self newer name)
        SemVer fromSeq(dep at("version")))

    _logUpdate := method(version,
        if (version > self _targetPackage version) then (
            Logger log("⬆ [[cyan bold;Updating [[reset;" ..
                "#{self _targetPackage name} " ..
                "from [[magenta bold;" ..
                "v#{self _targetPackage version asSeq}[[reset; " ..
                "to [[magenta bold;v#{version asSeq}", "output")
        ) elseif (version < self _targetPackage version) then (
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

    _checkGitBranch := method(name,
        branch := self package gitBranchForDep(name)

        if (branch isNil, return)

        Eerie sh("git checkout #{branch}", false, self newer dir path))

    _checkGitTag := method(version,
        Eerie sh("git checkout tags/#{version originalSeq}", 
            false,
            self newer dir path))

    # removes the old version of the dependency
    _removeOld := method(
        old := self package packageNamed(self newer name)
        self package removePackage(old))

    # installs the `newer` package
    _installNew := method(
        installer := Installer with(self package)
        installer install(self newer))

)

# Updater error types
Updater do (

    //doc Updater NoVersionsError
    NoVersionsError := Eerie Error clone setErrorMsg(
        "The package '#{call evalArgAt(0)}' has no tagged versions.")

    //doc Updater NotInstalledError
    NotInstalledError := Eerie Error clone setErrorMsg(
        "The dependency '#{call evalArgAt(0)}' is not installed.")

)
