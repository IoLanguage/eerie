IoAddonInstaller := Eerie PackageInstaller clone do(
  canInstall := method(_path,
    _pathDir := Directory with(_path)
    ioDir := _pathDir directoryNamed("io")

    _pathDir exists and(ioDir exists))

  install := method(
    dir := Directory with(self path)
    configFile := File with((self path) .. "/package.json")
    self config := if(configFile exists,
      Yajl parseJson(configFile openForReading contents),
      Map clone)
    configFile close

    if(File with((self path) .. "/protos") exists,
      self buildPackageJson,
      self extractDataFromPackageJson)

    if(dir directoryNamed("source") exists,
      self compile,
      dir createSubdirectory("source"))

    if(dir directoryNamed("bin") exists,
      self copyBinaries,
      dir createSubdirectory("bin"))

    true)

  extractDataFromPackageJson := method(
    providedProtos  := self config at("protos")
    protoDeps       := self config at("dependencies") ?at("protos")

    providedProtos ?isEmpty ifFalse(
      File with((self path) .. "/protos") create openForUpdating write(providedProtos join(" ")) close)

    protoDeps ?isEmpty ifFalse(
      File with((self path) .. "/depends") create openForUpdating write(protoDeps join(" ")) close)
    
    File with((self path) .. "/build.io") exists ifFalse(
      headerDeps  := self config at("dependencies") ?at("headers")
      libDeps     := self config at("dependencies") ?at("libs")

      buildIo := "AddonBuilder clone do(\n" asMutable
      libDeps ?foreach(lib,
        buildIo appendSeq("""  dependsOnLib("#{lib}")\n"""))
      headerDeps ?foreach(header,
        buildIo appendSeq("""  dependsOnHeader("#{header}")\n"""))
      buildIo appendSeq(")\n")

      File with((self path) .. "/build.io") create openForUpdating write(buildIo interpolate) close))

  compile := method(
    builderContext := Object clone
    builderContext doRelativeFile("AddonBuilder.io")
    prevPath := Directory currentWorkingDirectory
    Directory setCurrentWorkingDirectory(self path)

    addon := builderContext doFile((self path) .. "/build.io")
    addon folder := Directory with(self path)
    addon build(if(System platform split at(0) asLowercase == "windows",
      "-MD -Zi -DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE",
      "-Os -g -Wall -pipe -fno-strict-aliasing -DSANE_POPEN -DIOBINDINGS"))

    Directory setCurrentWorkingDirectory(prevPath)
    self)

  buildPackageJson := method(
    package := Map with(
      "dependencies", list(),
      "protos",       list())

    providedProtos := File with((self path) .. "/protos")
    protoDeps := File with((self path) .. "/depends")
    
    providedProtos exists ifTrue(
      providedProtos openForReading contents split(" ") foreach(pp, package at("protos") append(pp strip)))
    providedProtos close

    protoDeps exists ifTrue(
      protoDeps openForReading contents split(" ") foreach(pd, package at("dependencies") append(pd strip)))
    protoDeps close
    
    File with((self path) .. "/package.json") create openForUpdating write(package asJson) close

    self)

  copyBinaries := method(
    Eerie sh("chmod +x #{self path}/bin/*" interpolate)
    Directory with((self path) .. "/bin") files foreach(f,
      Eerie sh("ln -s #{f path} #{Eerie activeEnv path}/bin/#{f name}" interpolate)))
)