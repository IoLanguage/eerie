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
    self git("clone #{self uri} #{self path}" interpolate)
    self git("submodule init")
    true)

  update := method(path,
    self git("update")
    self git("submodule update"))
)
