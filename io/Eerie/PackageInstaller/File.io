FileInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    #dir := Directory with(_path)
    f := File with(_path)
    f exists and(f isRegularFile))

  install := method(
    File with((self path) .. "/package.json") create openForUpdating write(Map with(
      "author", User name,
      "dependencies", list(),
      "protos", list(Directory with(self path) filesWithExtension("io") first baseName makeFirstCharacterUppercase)
      ) asJson) close)
)