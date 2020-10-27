DirectoryDownloader := Eerie Downloader clone do (

    canDownload := method(url, Directory with(url) exists)

    download := method(
        self destDir createIfAbsent
        self url copyTo(self destDir path)
        return true)

)
