//metadoc Eerie Database category API
/*metadoc Eerie Database description
This proto represents Eerie database.*/

Database := Object clone do (

    //doc Database url Git URL for database repo.
    url := "https://github.com/IoLanguage/eerie-db.git"

    //doc Database dir Directory of database.
    dir := method(Directory with(Eerie root .. "/db"))

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

    /*doc Database manifestFor 
    Returns manifest `File` for package `name` if it's in the database,
    otherwise returns `nil`.*/
    manifestFor := method(name,
        # TODO
        name
    )

)
