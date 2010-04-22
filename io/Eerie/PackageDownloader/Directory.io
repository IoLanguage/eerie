DirectoryDownloader := Eerie PackageDownloader clone do(
  canDownload := method(uri,
    Directory with(uri) exists)

  download := method(
    Eerie sh("cp -R #{self uri}/* #{self path}" interpolate))
  
  update := getSlot("download")

  hasUpdates := method(
    # Directory doesen't provide lastDataChange method
    original  := File with(self uri)  lastDataChangeDate
    copy      := File with(self path) lastDataChangeDate
    original > copy)
)
