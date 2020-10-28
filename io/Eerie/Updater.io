//metadoc Updater category API
/*metadoc Updater description 
This proto is responsible for package updates. Notice, `Updater` updates only
locally (i.e. from a local directory). For downloading an updated package before
using `Updater` see [[Downloader]].*/

Updater := Object clone do (

    /*doc Updater newerPackage 
    The `Package` which is considered an updated version of
    `Updater targetPackage`.*/
    newerPackage := nil

    /*doc Updater targetPackage 
    The `Package`, which the updater should update.*/
    targetPackage := nil

    /*doc Updater targetVersion 
    A [[SemVer]] to which the updater should update. This can be shortened:
    - 1 - for all versions until 2.0.0-alpha
    - 1.0 - for all versions until 1.1.0-alpha*/
    //doc Updater setTargetVersion(SemVer) `Updater targetVersion` setter.
    targetVersion ::= nil

    /*doc Updater with(target, newer, version)
    Initializer, where:
    - target - the `Package` the updater should update
    - newer - the `Package` which is considered the updated version of the
    `target`
    - version - target `SemVer` (see `Updater targetVersion`)
    */
    with := method(target, newer, version,
        klone := self clone
        klone newerPackage = newer
        klone targetPackage = target
        klone targetVersion = version
        klone _checkSamePackage
        klone)

    update := method(
        # TODO
        # updateVersion == packageVersion
        #     nothing to update
        # updateVersion > packageVersion
        #     update to updateVersion
        # updateVersion < packageVersion
        #     DOWNGRADE to updateVersion
    )

    # check whether we trying to update the same package
    _checkSamePackage := method(
        if (self targetPackage name != self newerPackage name,
            Exception raise(DifferentPackageError with(""))))

    # find highest available version
    _highestVersion := method(
        highest := self targetVersion

        self _availableVersions foreach(ver, 
            if (ver <= self targetVersion and(
                ver isPre == self targetVersion isPre), 
                highest = ver))

        highest)

    # collect available versions from git tags as a list
    _availableVersions := method(
        cmdOut := Eerie sh("git tag", true, self newerPackage dir path)
        cmdOut stdout splitNoEmpties("\n") map(tag, SemVer fromSeq(tag)))

)

# Updater error types
Updater do (

    //doc Updater DifferentPackageError
    DifferentPackageError := Eerie Error clone setErrorMsg(
        "An attempt to update a package with a different one.")

)
