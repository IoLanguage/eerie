DirectoryDownloader := Downloader clone do (

    canDownload := method(url, Directory with(url) exists)

    download := method(
        self destDir createIfAbsent
        self Directory with(url) copyTo(self destDir)
        return true)

)
