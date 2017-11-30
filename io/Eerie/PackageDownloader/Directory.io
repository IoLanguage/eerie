DirectoryDownloader := Eerie PackageDownloader clone do(
  canDownload := method(uri,
    Directory with(uri) exists)

  download := method(
    # Should we copy dot files also? Not copying .git/.svn/etc folders
    # is ok, but what about the rest?
    Eerie sh("cp -R #{self uri}/* #{self path}" interpolate)
  )
  
  update := getSlot("download")

  hasUpdates := method(
    # It actually checks if there were any changes on the directory itself
    # not really what we need.
    # TODO: 
    # Directory doesen't provide lastDataChange method
    #original  := File with(self uri)  lastDataChangeDate
    #copy      := File with(self path) lastDataChangeDate
    #original > copy

    true)
)
