PackageInstaller := Object clone do(
  //doc PackageInstaller path Path to at which package is located.
  path  ::= nil

  with := method(_path,
    self clone setPath(_path))

  detect := method(_path,
    self instances foreachSlot(slotName, installer,
      installer canInstall(_path) ifTrue(
        return(installer with(_path))))

    Exception raise("Don't know how to install package at #{_path}" interpolate))

  //doc PackageInstaller canInstall(path)
  canInstall := method(path, false)
  //doc PackageInstaller install()
  install := method(false)
)

PackageInstaller instances := Object clone do(
  doRelativeFile("PackageInstaller/File.io")
  doRelativeFile("PackageInstaller/Directory.io")
  doRelativeFile("PackageInstaller/IoAddon.io")
)
