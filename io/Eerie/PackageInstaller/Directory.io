DirectoryInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    dir := Directory with(_path)
    packageJson := File with(_path .. "/package.json")
    dir exists and(dir filesWithExtension("io") isEmpty not) and(packageJson exists not))

  install := method(
    ioDir := self dirNamed("io") create

    protosList := list()
    self root filesWithExtension("io") map(ioFile,
      ioFile baseName at(0) isUppercase ifTrue(
        protoList append(ioFile baseName)))

    Eerie sh("mv #{self path}/*.io #{ioDir path}" interpolate)

    self fileNamed("package.json") remove create openForUpdating write(Map with(
      "author", User name,
      "dependencies", list(),
      "protos", protosList
    ) asJson) close)
)