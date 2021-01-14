//metadoc Loader category API
/*metadoc Loader description 
The purpose of this proto is to load Eerie itself, global packages and the
current directory (if it's a package). 

It's called automatically by the Io importer, if `EERIEDIR` environment variable
is set.*/

Loader := Object clone do (

    //doc Loader load Load Eerie and packages.
    load := method(
        ctx := Object clone
        ctx Object := ctx
        ctx do (
            doRelativeFile("Extensions.io")
            doRelativeFile("SemVer.io")
            doRelativeFile("Eerie.io")
            doRelativeFile("Database.io")
            doRelativeFile("Package.io")
            Package global load)

        cwd := Directory currentWorkingDirectory

        # checking if cwd is Eerie to prevent from loading it twice
        #
        # EERIDIR value may be different from Directory path, so we use
        # initialized root Directory of the global package instead of 
        # Eerie root
        if (Eerie Package global struct root path == cwd, return)

        if (Eerie Package Structure isPackage(Directory with(cwd)), 
            Eerie Package with(cwd) load))

)
