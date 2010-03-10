PackageDownloader := Object clone do(
  //doc PackageDownloader uri 
  uri         ::= nil
  //doc PackageDownloader path
  path        ::= nil

  with := method(_uri, _path,
    self clone setUri(_uri) setPath(_path))

  detect := method(_uri, _path,
    self instances foreachSlot(slotName, downloader,
      downloader canDownload(_uri) ifTrue(
        return(downloader with(_uri, _path))))

    Exception raise("Don't know how to download package from #{_uri}" interpolate))

  canDownload := method(uri, false)
  download    := method(false)

  createSkeleton := method(
    root := Directory with(self path)
    root createSubdirectory("io")
    root createSubdirectory("bin")
    root createSubdirectory("hooks"))
)

PackageDownloader instances := Object clone
PackageDownloader instances doRelativeFile("PackageDownloader/File.io")
PackageDownloader instances doRelativeFile("PackageDownloader/Directory.io")
PackageDownloader instances doRelativeFile("PackageDownloader/Vcs.io")
