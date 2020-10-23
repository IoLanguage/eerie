//metadoc Downloader category API
/*metadoc Downloader description 
The abstract proto the purpose of which is to detect how and then to download a
package dependency into the `_tmp` directory.*/

Downloader := Object clone do(

    # TODO сначала downloader должен проверять базу eerie, есть ли там пакет.
    # Если есть, то берем ссылку оттуда

    /*doc Downloader package 
    The `Package` for which downloader downloads the dependency.*/
    package := nil

    //doc Downloader url 
    url ::= nil

    //doc Downloader path
    path ::= nil

    /*doc Downloader root Directory object pointing to
    [[Downloader path]].*/
    root := method(self root = Directory with(self path))

    //doc Downloader with(url, path) Creates a new [[Downloader]].
    with := method(uri_, path_, self clone setUri(uri_) setPath(path_))

    /*doc Downloader detect(url, path)
    Looks for [[Downloader]] which understands provided URI. If suitable
    downloader is found, a clone with provided URI and path is returned.
    Otherwise an exception is thrown.*/
    detect := method(uri_, path_,
        self instances foreachSlot(slotName, downloader,
            downloader canDownload(uri_) ifTrue(
                Eerie log("Using #{slotName} for #{uri_}", "debug")
                return(downloader with(uri_, path_))))

        Exception raise(
            "Don't know how to download package from #{uri_}" interpolate))

    /*doc Downloader canDownload(url) 
    Returns `true` if it understands provided URI and `false` otherwise.*/
    canDownload := method(url, false)

    /*doc Downloader download
    Downloads package from `self url` to `self path`.*/
    download := method(false)

    //doc Downloader hasUpdates
    hasUpdates := method(false)

    //doc Downloader update Updates the package.
    update := method(true)

)

# Error types
Downloader do (

    //doc Downloader FailedDownloadError
    FailedDownloadError := Eerie Error clone setErrorMsg(
        "Fetching package from #{call evalArgAt(0)} failed.")

)

//doc Downloader instances Contains all Downloader clones
Downloader instances := Object clone do (
    doRelativeFile("downloaders/Vcs.io")
    doRelativeFile("downloaders/Archive.io")
    doRelativeFile("downloaders/Directory.io")
)
