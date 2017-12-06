//metadoc PackageInstaller category Utilites
//metadoc PackageInstaller description

PackageInstaller := Object clone do(
  compileFlags := if(System platform split first asLowercase == "windows",
    "-MD -Zi -DWIN32 -DNDEBUG -DIOBINDINGS -D_CRT_SECURE_NO_DEPRECATE",
    "-Os -g -Wall -pipe -fno-strict-aliasing -DSANE_POPEN -DIOBINDINGS"
  )

  //doc PackageInstaller path Path to at which package is located.
  path  ::= nil

  //doc PackageInstaller root Directory with PackageInstallers' path.
  root   := method(
    self root = Directory with(self path))

  //doc PackageInstaller config Contains contents of a package.json
  config ::= nil

  init := method(
    self config = Map clone)

  //doc PackageInstaller with(path)
  with := method(_path,
    self clone setPath(_path))

  //doc PacakgeInstaller detect(path) Returns first PackageInstaller which can install package at provided path.
  detect := method(_path,
    self instances foreachSlot(slotName, installer,
      installer canInstall(_path) ifTrue(
        return(installer with(_path))))

    Eerie revertConfig
    Exception raise("Don't know how to install package at #{_path}" interpolate))

  //doc PackageInstaller canInstall(path)
  canInstall := method(path, false)

  //doc PackageInstaller install
  install := method(false)

  //doc PackageInstaller fileNamed(name) Returns an File relative to root directory.
  fileNamed := method(name,
    self root fileNamed(name))

  //doc PackageInstaller dirNamed(name) Returns an Directory relative to root directory.
  dirNamed := method(name,
    self root directoryNamed(name))

  //doc PackageInstaller loadConfig Looks for configuration data (in <code>protos</code> and <code>deps</code>) and then loads package.json.
  loadConfig := method(
    if(self fileNamed("protos") exists,
      self buildPackageJson,
      self extractDataFromPackageJson)

    configFile := self fileNamed("package.json")
    configFile exists ifTrue(
      self setConfig(Yajl parseJson(configFile openForReading contents))
      configFile close))

  /*doc PackageInstaller extractDataFromPackageJson
  Creates <code>protos</code>, <code>deps</code> and <code>build.io</code> files from <code>package.json</code>*/
  extractDataFromPackageJson := method(
    providedProtos  := self config at("protos") ?join(" ")
    providedProtos isNil ifTrue(
      providedProtos = "")

    deps            := self config at("dependencies")
    protoDeps       := deps ?at("protos") ?join(" ")
    protoDeps isNil ifTrue(
      protoDeps = "")

    self fileNamed("protos")  create openForUpdating write(providedProtos) close
    self fileNamed("depends") create openForUpdating write(protoDeps) close

    self fileNamed("build.io") exists ifFalse(
      headerDeps  := deps ?at("headers")
      libDeps     := deps ?at("libs")

      buildIo := list("AddonBuilder clone do(")
      libDeps ?foreach(lib,
        buildIo append("""  dependsOnLib("#{lib}")"""))
      headerDeps ?foreach(header,
        buildIo append("""  dependsOnHeader("#{header}")"""))
      buildIo append(")\n")

      self fileNamed("build.io") remove create openForUpdating write(buildIo join("\n") interpolate) close)
    )

  //doc PackageInstaller buildPackageJson
  buildPackageJson := method(
    package := Map with(
      "dependencies", list(),
      "protos",       list()
    )

    providedProtos := self fileNamed("protos")
    protoDeps := self fileNamed("depends")

    providedProtos exists ifTrue(
      providedProtos openForReading contents split(" ") foreach(pp, package at("protos") append(pp strip)))
    providedProtos close

    protoDeps exists ifTrue(
      protoDeps openForReading contents split(" ") foreach(pd, package at("dependencies") append(pd strip)))
    protoDeps close

    pJson := self fileNamed("package.json")
    pJson exists ifFalse(
      pJson create openForUpdating write(package asJson)
    )
    pJson close

    self
  )

  //doc PackageInstaller compile Compiles the package.
  compile := method(
    builderContext := Object clone
    builderContext doRelativeFile("AddonBuilder.io")
    prevPath := Directory currentWorkingDirectory
    Directory setCurrentWorkingDirectory(self path)

    addon := builderContext doFile((self path) .. "/build.io")
    addon folder := Directory with(self path)
    addon build(self compileFlags)

    Directory setCurrentWorkingDirectory(prevPath)
    self)

  //doc PackageInstaller copyBinaries Creates symlinks for files <code>bin</code> directory in active environment's <code>bin</code>.
  copyBinaries := method(
    Eerie sh("chmod u+x #{self path}/bin/*" interpolate)
    self dirNamed("bin") files foreach(original,
      link := File with(Eerie usedEnv path .. "/bin/" .. original name)
      link exists ifFalse(
        Eerie sh("ln -s #{original path} #{link path}" interpolate))))
)

//doc PackageInstaller instances
PackageInstaller instances := Object clone do(
  //doc PackageInstaller File Installs single files.
  doRelativeFile("PackageInstaller/File.io")
  //doc PackageInstaller Directory Installs whole directories.
  doRelativeFile("PackageInstaller/Directory.io")
  //doc PacakgeInstaller IoAddon Installs directories structured as an Io addon.
  doRelativeFile("PackageInstaller/IoAddon.io")
)
