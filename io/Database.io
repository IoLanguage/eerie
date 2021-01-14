//metadoc Eerie Database category API
/*metadoc Eerie Database description
This proto represents Eerie database.*/

Database := Object clone do (

    //doc Database url Git URL for database repo.
    url := "https://github.com/IoLanguage/eerie-db.git"

    //doc Database dir `Directory` of the database.
    dir := method(Directory with(Eerie root .. "/db"))

    _cache := nil

    init := method(if (self dir exists not, self _clone))

    _clone := method(
        Logger log("Database not found")
        Logger log("🔄 [[cyan bold;Cloning [[reset;database" , "output")
        System sh("git clone #{self url} #{self dir path}", true))

    /*doc Database needsUpdate 
    Returns whether database is outdated (`true`) or not (`false`).*/
    needsUpdate := method(
        cmdOut := System sh("git fetch --dry-run", true, self dir path)
        cmdOut stdout isEmpty not)

    //doc Database update Sync database with remote.
    update := method(
        Logger log("🔄 [[cyan bold;Updating [[reset;database" , "output")
        System sh("git fetch --prune", true, self dir path)
        System sh("git merge", true, self dir path)
        # we don't want for update checker to slow down the builds, so we
        # update only once per session
        self needsUpdate = false)

    /*doc Database valueFor(pkgName, key)
    Returns value at `key` (`Sequence`) from package (`pkgName` (`Sequence`))
    manifest if the package in the database, otherwise returns `nil`. 

    The `key` is a field name with subfields separated by dot: `foo.bar.baz`.*/
    valueFor := method(pkgName, key,
        value := self manifestFor(pkgName)
        if (value isNil, return nil)

        split := key split(".")
        split foreach(key, value = value at(key))

        value)

    /*doc Database manifestFor(name) 
    Returns manifest as a `Map` for package `name` if it's in the database,
    otherwise returns `nil`.*/
    manifestFor := method(name,
        if (self _cache ?at(name) isNil not, return self _cache at(name))

        manifest := File with(self dir path .. "/db/#{name}.json" interpolate)

        if (manifest exists not, return nil)
        
        parsed := manifest contents parseJson

        self _cacheManifest(name, parsed)
        
        parsed)

    _cacheManifest := method(name, manifest,
        self _cache = self _cache ifNilEval(Map clone)
        self _cache atPut(name, manifest))

)

Database clone = Database do(init)
