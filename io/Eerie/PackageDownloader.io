PackageDownloader := Object clone do(
  //doc PackageDownloader uri 
  uri         ::= nil
  //doc PackageDownloader path
  path        ::= nil

  //doc PackageDownloader root Directory object pointing to [[PackageDownloader path]].
  root := method(
    self root = Directory with(self path))

  //doc PackageDownloader with(uri, path) Creates a new [[PackgeDownloader]].
  with := method(uri_, path_,
    self clone setUri(uri_) setPath(path_))

  /*doc PackageDownloader with(uri, path)
  Looks for [[PackageDownloader]] which understands provided URI. If suitable downloader is found,
  a clone with provided URI and path is returned, otherwise [[Eerie revertConfig]] is called and an exception is thrown.
  */
  detect := method(uri_, path_,
    self instances foreachSlot(slotName, downloader,
      downloader canDownload(uri_) ifTrue(
        return(downloader with(uri_, path_))))

    Eerie revertConfig
    Exception raise("Don't know how to download package from #{uri_}" interpolate))

  //doc PackageDownloader canDownload(uri) Returns <code>true</code> if it understands provided URI. <code>false</code> otherwise.
  canDownload := method(uri, false)
  //doc PackageDownloader download Downloads package from <code>self uri</code> to <code>self path</code>.
  download    := method(false)
  //doc PackageDownloader update Updates the package. Returns false if there is no need for update.
  update      := method(true)

  //doc PackageDownloader createSkeleton Creates required directories, <code>io</code>, <code>bin</code> and <code>hooks</code>.
  createSkeleton := method(
    self root createSubdirectory("io")
    self root createSubdirectory("bin")
    self root createSubdirectory("hooks"))
)

//doc PackageDownloader instances Contains all PackageDownloader clones
PackageDownloader instances := Object clone do(
  doRelativeFile("PackageDownloader/Vcs.io")
  doRelativeFile("PackageDownloader/File.io")
  doRelativeFile("PackageDownloader/Archive.io")
  doRelativeFile("PackageDownloader/Directory.io")
)
