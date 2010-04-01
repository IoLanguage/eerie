PackageDownloader := Object clone do(
  //doc PackageDownloader uri 
  uri         ::= nil
  //doc PackageDownloader path
  path        ::= nil
  
  root := method(
    self root = Directory with(self path))

  with := method(uri_, path_,
    self clone setUri(uri_) setPath(path_))

  detect := method(uri_, path_,
    self instances foreachSlot(slotName, downloader,
      downloader canDownload(uri_) ifTrue(
        return(downloader with(uri_, path_))))

    Eerie revertConfig
    Exception raise("Don't know how to download package from #{uri_}" interpolate))

  canDownload := method(uri, false)
  download    := method(false)

  createSkeleton := method(
    self root createSubdirectory("io")
    self root createSubdirectory("bin")
    self root createSubdirectory("hooks"))
)

PackageDownloader instances := Object clone do(
  doRelativeFile("PackageDownloader/Vcs.io")
  doRelativeFile("PackageDownloader/File.io")
  doRelativeFile("PackageDownloader/Archive.io")
  doRelativeFile("PackageDownloader/Directory.io")
)
