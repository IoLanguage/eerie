PackageDownloader := Object clone do(
  //doc PackageDownloader uri 
  uri         ::= nil
  //doc PackageDownloader path
  path        ::= nil

  with := method(uri_, path_,
    self clone setUri(uri_) setPath(path_))

  detect := method(uri_, path_,
    self instances foreachSlot(slotName, downloader,
      downloader canDownload(uri_) ifTrue(
        return(downloader with(uri_, path_))))

    Exception raise("Don't know how to download package from #{uri_}" interpolate))

  canDownload := method(uri, false)
  download    := method(false)

  createSkeleton := method(
    root := Directory with(self path)
    root createSubdirectory("io")
    root createSubdirectory("bin")
    root createSubdirectory("hooks"))
)

PackageDownloader instances := Object clone do(
  doRelativeFile("PackageDownloader/File.io")
  doRelativeFile("PackageDownloader/Directory.io")
  doRelativeFile("PackageDownloader/Vcs.io")
)
