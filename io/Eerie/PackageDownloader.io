//metadoc PackageDownloader category API
//metadoc PackageDownloader description

PackageDownloader := Object clone do(
    //doc PackageDownloader uri 
    uri ::= nil

    //doc PackageDownloader path
    path ::= nil

    /*doc PackageDownloader root Directory object pointing to
    [[PackageDownloader path]].*/
    root := method(self root = Directory with(self path))

    //doc PackageDownloader with(uri, path) Creates a new [[PackgeDownloader]].
    with := method(uri_, path_, self clone setUri(uri_) setPath(path_))

    /*doc PackageDownloader detect(uri, path)
    Looks for [[PackageDownloader]] which understands provided URI. If suitable
    downloader is found, a clone with provided URI and path is returned an
    exception is thrown.
    */
    detect := method(uri_, path_,
        self instances foreachSlot(slotName, downloader,
            downloader canDownload(uri_) ifTrue(
                Eerie log("Using #{slotName} for #{uri_}", "debug")
                return(downloader with(uri_, path_))))

        Exception raise(
            "Don't know how to download package from #{uri_}" interpolate))

    /*doc PackageDownloader canDownload(uri) Returns `true` if it understands
    provided URI. `false` otherwise.*/
    canDownload := method(uri, false)

    /*doc PackageDownloader download Downloads package from `self uri` to 
    `self path`.*/
    download := method(false)

    //doc PackageDownloader hasUpdates
    hasUpdates := method(false)

    //doc PackageDownloader update Updates the package.
    update := method(true)

    /*doc PackageDownloader createSkeleton Creates required directories, `io`,
    `bin`, `hooks` and `source`.*/
    createSkeleton := method(
        self root createSubdirectory("io")
        self root createSubdirectory("bin")
        self root createSubdirectory("hooks")
        self root createSubdirectory("source"))
)

//doc PackageDownloader instances Contains all PackageDownloader clones
PackageDownloader instances := Object clone do(
    doRelativeFile("PackageDownloader/Vcs.io")
    doRelativeFile("PackageDownloader/File.io")
    doRelativeFile("PackageDownloader/Archive.io")
    doRelativeFile("PackageDownloader/Directory.io")
)
