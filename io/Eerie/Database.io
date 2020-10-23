//metadoc Eerie Database category API
/*metadoc Eerie Database description
This proto represents Eerie database.*/

Database := Object clone do (

    //doc Database url Git URL for database repo.
    url := "https://github.com/IoLanguage/eerie-db.git"

    //doc Database dir `Directory` of the database.
    dir := method(Directory with(Eerie root .. "/db"))

    _cachedConfig := nil

    init := method(if (self dir exists not, self _clone))

    _clone := method(
        Eerie log("Database not found")
        Eerie log("🔄  Cloning database" asUTF8, "output")
        Eerie sh("git clone #{self url} #{self dir path}" interpolate, true))

    /*doc Database needsUpdate 
    Returns whether database is outdated (`true`) or not (`false`).*/
    needsUpdate := method(
        Eerie sh("git fetch", true, self dir path)
        cmdOut := Eerie sh("git status", true, self dir path)
        cmdOut stdout containsSeq("Your branch is up to date with") not)

    //doc Database update Sync database with remote.
    update := method(
        Eerie log("🔄  Updating database" asUTF8, "output")
        Eerie sh("git fetch --prune", true, self dir path)
        Eerie sh("git merge", true, self dir path))

    /*doc Database valueFor(pkgName, key)
    Returns value at `key` (`Sequence`) from package (`pkgName` (`Sequence`))
    manifest if the package in the database, otherwise returns `nil`. 

    The `key` is a field name with subfields separated by dot: `foo.bar.baz`.*/
    valueFor := method(pkgName, key,
        manifest := self manifestFor(pkgName)
        if (manifest isNil, return nil)

        split := key split(".")
        value := self _parseManifest(manifest)
        split foreach(key, value = value at(key))

        value)

    # use cached config is possible, otherwise - cache it
    _parseManifest := method(manifest,
        if (self _cachedConfig isNil, 
            self _cachedConfig = manifest contents parseJson)

        if (self _cachedConfig at("name") != manifest baseName,
            self _cachedConfig = manifest contents parseJson)

        self _cachedConfig)

    /*doc Database manifestFor(name) 
    Returns manifest `File` for package `name` if it's in the database,
    otherwise returns `nil`.*/
    manifestFor := method(name,
        manifest := File with(self dir path .. "/db/#{name}.json" interpolate)
        if (manifest exists not, return nil)
        manifest)

)
