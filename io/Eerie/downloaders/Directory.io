DirectoryDownloader := Eerie Downloader clone do(
    canDownload := method(uri,
        Directory with(uri) exists
    )

    download := method(
        self uri copyTo(self path)
        return true)

    update := getSlot("download")

    hasUpdates := method(
        # It actually checks if there were any changes on the directory itself
        # not really what we need.
        # TODO: 
        # Directory doesen't provide lastDataChange method
        #original  := File with(self uri)  lastDataChangeDate
        #copy      := File with(self path) lastDataChangeDate
        #original > copy

        true
    )
)
