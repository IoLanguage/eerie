DirectoryInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    dir := Directory with(_path)
    packageJson := File with(_path .. "/package.json")
    dir exists and(dir filesWithExtension("io") isEmpty not) and(packageJson exists not))

  protosList := method(
    self protosList = list()
    self root filesWithExtension("io") map(ioFile,
      ioFile baseName at(0) isUppercase ifTrue(
        self protoList append(ioFile baseName)))

    self protosList)

  install := method(
    self loadConfig
    ioDir := self dirNamed("io") create
    Eerie sh("mv #{self path}/*.io #{ioDir path}" interpolate))

  buildPackageJson := method(
    pkgInfo := self fileNamed("package.json")
    pkgInfo exists ifFalse(
      pkgInfo create openForUpdating write(Map with(
        "author", User name,
        "dependencies", list(),
        "protos", self protosList
      ) asJson) close))

  extractDataFromPackageJson := method(
    deps := self fileNamed("depends")
    deps exists ifFalse(deps create openForUpdating write("\n") close)

    pprotos := self fileNamed("protos")
    pprotos exists ifFalse(deps create openForUpdating write(self protosList join(" ") .. "\n") close))
)