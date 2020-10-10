//metadoc Downloader category API
//metadoc Downloader description

Downloader := Object clone do(
    //doc Downloader uri 
    uri ::= nil

    //doc Downloader path
    path ::= nil

    /*doc Downloader root Directory object pointing to
    [[Downloader path]].*/
    root := method(self root = Directory with(self path))

    //doc Downloader with(uri, path) Creates a new [[Downloader]].
    with := method(uri_, path_, self clone setUri(uri_) setPath(path_))

    /*doc Downloader detect(uri, path)
    Looks for [[Downloader]] which understands provided URI. If suitable
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

    /*doc Downloader canDownload(uri) Returns `true` if it understands
    provided URI. `false` otherwise.*/
    canDownload := method(uri, false)

    /*doc Downloader download Downloads package from `self uri` to 
    `self path`.*/
    download := method(false)

    //doc Downloader hasUpdates
    hasUpdates := method(false)

    //doc Downloader update Updates the package.
    update := method(true)

    /*doc Downloader createSkeleton Creates required directories, `io`,
    `bin`, `hooks` and `source`.*/
    createSkeleton := method(
        self root createSubdirectory("io")
        self root createSubdirectory("bin")
        self root createSubdirectory("hooks")
        self root createSubdirectory("source"))
)

# Error types
Downloader do (
    //doc Downloader FailedDownloadError
    FailedDownloadError := Eerie Error clone setErrorMsg(
        "Fetching package from #{call evalArgAt(0)} failed.")
)

//doc Downloader instances Contains all Downloader clones
Downloader instances := Object clone do(
    doRelativeFile("Downloader/Vcs.io")
    doRelativeFile("Downloader/File.io")
    doRelativeFile("Downloader/Archive.io")
    doRelativeFile("Downloader/Directory.io")
)
