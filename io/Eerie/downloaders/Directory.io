DirectoryDownloader := Eerie Downloader clone do(
    canDownload := method(url,
        Directory with(url) exists)

    download := method(
        self url copyTo(self destDir path)
        return true)

    update := getSlot("download")

    hasUpdates := method(
        # It actually checks if there were any changes on the directory itself
        # not really what we need.
        # TODO: 
        # Directory doesen't provide lastDataChange method
        #original  := File with(self url)  lastDataChangeDate
        #copy      := File with(self destDir path) lastDataChangeDate
        #original > copy

        true
    )
)
