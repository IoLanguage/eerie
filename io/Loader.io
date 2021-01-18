//metadoc Loader category API
/*metadoc Loader description 
The purpose of this proto is to load Eerie itself, global packages and the
current directory (if it's a package). 

It's called automatically by the Io importer, if `EERIEDIR` environment variable
is set.*/

Loader := Object clone do (

    /*doc Loader load(context) 
    Loads Eerie, global packages and package in the current working directory
    (if it's a package).

    The `context` argument is an optional context in which the packages should
    be loaded.*/
    load := method(context,
        ctx := Object clone
        ctx Object := ctx
        ctx context := context
        ctx do (
            doRelativeFile("Extensions.io")
            doRelativeFile("SemVer.io")
            doRelativeFile("Eerie.io")
            doRelativeFile("Database.io")
            doRelativeFile("Package.io")
            Package global load(context))

        cwd := Directory currentWorkingDirectory

        context = context ifNilEval(Lobby)

        # checking if cwd is Eerie to prevent from loading it twice
        #
        # EERIDIR value may be different from Directory path, so we use
        # initialized root Directory of the global package instead of 
        # Eerie root
        if (context Eerie Package global struct root path == cwd, return)

        if (context Eerie Package Structure isPackage(Directory with(cwd)), 
            context Eerie Package with(cwd) load(context)))

    /*doc Loader unload(context) 
    Unload Eerie and the current package.

    The `context` is optional. The method will use `Lobby`, if it isn't
    specified.*/
    unload := method(context,
        context = context ifNilEval(Lobby)

        if (context hasSlot("Eerie") not, return)

        cwd := Directory currentWorkingDirectory
        
        if (context Eerie Package global struct root path == cwd not, 
            self _unloadCurrentPackage(context))

        context removeSlot("Eerie"))

    _unloadCurrentPackage := method(context,
        if (context Eerie Package Structure isPackage(Directory with(cwd)), 
            package := context Eerie Package with(cwd)
            context removeSlot(package struct manifest name)))

)
