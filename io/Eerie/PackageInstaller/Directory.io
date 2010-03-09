DirectoryInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    dir := Directory with(_path)
    packageJson := File with(_path .. "/package.json")
    dir exists and(dir filesWithExtension("io") isEmpty not) and(packageJson exists not))

  install := method(
    root := Directory with(self path)
    ioDir := root directoryNamed("io") create
    
    protosList := list()
    root filesWithExtension("io") foreach(ioFile,
      ioFile baseName at(0) isUppercase ifTrue(
        protoList append(ioFile baseName)))

    Eerie sh("mv #{self path}/*.io #{ioDir path}" interpolate)

    File with((self path) .. "/package.json") create openForUpdating write(Map with(
      "author", User name,
      "dependencies", list(),
      "protos", protosList
    ) asJson) close)
)