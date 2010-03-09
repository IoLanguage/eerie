GitDownloader := Eerie PackageDownloader clone do(
  git := method(gitArgs,
    pwd := Directory currentWorkingDirectory
    Directory setCurrentWorkingDirectory(self path)
    r := Eerie sh("git " .. gitArgs)
    Directory setCurrentWorkingDirectory(pwd)

    r)

  canDownload := method(uri,
    (uri containsSeq("git://")) or(uri containsSeq(".git")))

  download := method(
    # Package.io will create addon's directory but,
    # Git insists on creating it on its own. 
    Directory with(self path) remove
    self git("clone #{self uri} #{self path}" interpolate)
    self git("submodule init")
    self git("submodule update")
    true)

  update := method(path,
    self git("update")
    self git("submodule update"))
)
