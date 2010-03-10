IoAddonInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    _pathDir := Directory with(_path)
    ioDir := _pathDir directoryNamed("io")

    _pathDir exists and(ioDir exists))

  install := method(
    self loadConfig

    if(self fileNamed("protos") exists,
      self buildPackageJson,
      self extractDataFromPackageJson)

    if(self dirNamed("source") exists,
      self compile,
      self root createSubdirectory("source"))

    if(self dirNamed("bin") exists,
      self copyBinaries,
      self root createSubdirectory("bin"))

    true)
)