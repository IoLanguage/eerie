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
        ctx do (
            doRelativeFile("Eerie.io")
            Eerie Package global load
            cwd := Directory currentWorkingDirectory
            if (Eerie Package Structure isPackage(Directory with(cwd)), 
                Package with(cwd))))

)
