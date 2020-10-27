//metadoc Downloader category API
/*metadoc Downloader description 
The proto the purpose of which is to detect how and then to download a package.
The `Downloader` itself is abstract, look specific implementations for
particular strategies (directory, archive or version control system (VCS)).*/

Downloader := Object clone do (

    /*doc Downloader url 
    URL from which `Downloader` should download the package.*/
    //doc Downloader setUrl `Downloader url` setter.
    url ::= nil

    //doc Downloader destDir The destination `Directory`, to where to download.
    //doc Downloader setDestDir `Downloader destDir` setter. 
    destDir ::= nil

    /*doc Downloader with(url, dir) 
    [[Downloader]] initializer, where `url` is a `Sequence` from where the
    downloader should download, and `dir` is a `Directory` into which the
    downloader should download.*/
    with := method(url, dir, self clone setUrl(url) setDestDir(dir))

    /*doc Downloader detect(url, path)
    Looks for [[Downloader]] which understands provided URI. If suitable
    downloader is found, a clone with provided URI and path is returned.
    Otherwise an exception is thrown.*/
    detect := method(query, path,
        uri := Eerie database valueFor(query, "url") ifNilEval(query)

        self instances foreachSlot(slotName, downloader,
            downloader canDownload(query) ifTrue(
                Eerie log("Using #{slotName} for #{query}", "debug")
                return downloader with(query, path)))

        Exception raise(DetectError with(query)))

    /*doc Downloader canDownload(url) 
    Returns `true` if it understands provided URI and `false` otherwise.*/
    canDownload := method(url, false)

    /*doc Downloader download
    Downloads package from `self url` to `self path`.*/
    download := method(false)

)

# Error types
Downloader do (

    //doc Downloader DetectError
    DetectError := Eerie Error clone setErrorMsg(
        "Don't know hot to download the package from #{call evalArgAt(0)}")

)

//doc Downloader instances Contains all Downloader clones
Downloader instances := Object clone do (
    doRelativeFile("downloaders/Vcs.io")
    doRelativeFile("downloaders/Archive.io")
    doRelativeFile("downloaders/Directory.io")
)
