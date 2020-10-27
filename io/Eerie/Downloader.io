//metadoc Downloader category API
/*metadoc Downloader description 
The purpose of this proto is to detect how and then to download a package. The
`Downloader` itself is abstract, look specific implementations for particular
strategies (directory, archive or version control system (VCS)).*/

Downloader := Object clone do (

    /*doc Downloader url 
    URL from which `Downloader` should download the package.*/
    //doc Downloader setUrl `Downloader url` setter.
    url ::= nil

    //doc Downloader destDir The destination `Directory`, to where to download.
    //doc Downloader setDestDir `Downloader destDir` setter. 
    destDir ::= nil

    /*doc Downloader with(url, root) 
    [[Downloader]] initializer, where `url` is a `Sequence` from where the
    downloader should download, and `root` is a `Directory` where the downloader
    will create a directory (`Downloader destDir`) with random name to download
    package into it.*/
    with := method(url, root,
        destName := Random bytes(16) asHex
        self clone setUrl(url) setDestDir(root createSubdirectory(destName)))

    /*doc Downloader detect(query, root)
    - `query` - package name, URL or path to a local directory
    - `root` - root `Directory` where the downloader will create a directory to
    where to download package

    First it tries to find the package in the database and then it looks for an
    instance of [[Downloader]], which understands provided URL.
    
    If a suitable downloader is found, returns an instance of it initialized
    using `Downloader with(url, dir)`, otherwise raises an exception with
    `Downloader DetectError`.*/
    detect := method(query, dir,
        uri := Eerie database valueFor(query, "url") ifNilEval(query)

        self instances foreachSlot(slotName, downloader,
            downloader canDownload(uri) ifTrue(
                Eerie log("Using #{slotName} for #{query}", "debug")
                return downloader with(uri, dir)))

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
    doRelativeFile("downloaders/vcs.io")
    doRelativeFile("downloaders/archive.io")
    doRelativeFile("downloaders/directory.io")
)
