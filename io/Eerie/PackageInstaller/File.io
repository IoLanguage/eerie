FileInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    #dir := Directory with(_path)
    f := File with(_path)
    f exists and(f isRegularFile))

  install := method(
    self fileNamed("package.json") remove create openForUpdating write(Map with(
      "author", User name,
      "dependencies", list(),
      "protos", list(self root filesWithExtension("io") first baseName makeFirstCharacterUppercase)
      ) asJson) close)
)