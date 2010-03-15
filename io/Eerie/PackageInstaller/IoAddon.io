IoAddonInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    _pathDir := Directory with(_path)
    ioDir := _pathDir directoryNamed("io")

    _pathDir exists and(ioDir exists))

  install := method(
    sourceDir := self dirNamed("source")
    if(sourceDir exists and sourceDir files isEmpty not,
      self compile,
      sourceDir create)

    binDir := self dirNamed("bin")
    if(binDir exists and binDir files isEmpty not,
      self copyBinaries,
      binDir create)

    true)
)
