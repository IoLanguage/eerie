Eerie := Object clone do(
  root                ::= System getEnvironmentVariable("EERIEDIR")
  tmpDir              ::= root .. "/tmp"
  # activeEnv will be set from Eerie/Env.io
  activeEnv           ::= nil
  configFile          :=  nil
  config              ::= nil
  configBackup        ::= nil
  envs                := List clone

  sh := method(cmd, logFailure, dir,
    self log(cmd, "console")
    dir isNil ifFalse(
      cmd = "cd " .. dir .. " && " .. cmd
      prevDir := Directory currentWorkingDirectory
      Directory setCurrentWorkingDirectory(dir))

    cmdOut := System runCommand(cmd)
    stdOut := cmdOut stdout
    stdErr := cmdOut stderr

    dir isNil ifFalse(
      Directory setCurrentWorkingDirectory(prevDir))

    System system("rm -f *-stdout")
    System system("rm -f *-stderr")

    if(cmdOut exitStatus != 0,
      if(logFailure == false,
        false
      ,
        self log("Last command exited with the following error:", "error")
        self log(stdOut, "error")
        self log(stdErr, "error")
        System exit(1))
    ,
      true))

  _logMods := Map with(
    "info",     " - ",
    "error",    " ! ",
    "console",  " > ",
    "output",   "")
  log := method(str, mode,
    mode ifNil(mode = "info")
    ((self _logMods at(mode)) .. str) interpolate(call sender) println)

  init := method(
    self configFile := File with((self root) .. "/config.json") openForUpdating
    self setConfig(Yajl parseJson(self configFile contents))
    self setConfigBackup(self configFile contents)

    self config at("envs") ?foreach(name, envConfig,
      Eerie Env withConfig(name, envConfig))

    activeEnv_ := self config at("activeEnv")
    activeEnv_ isNil ifFalse(
      self setActiveEnv(Eerie Env named(activeEnv_))
      self activeEnv use)
    self)

  updateConfig := method(key, value,
    self config atPut(key, value)
    self saveConfig)

  saveConfig := method(
    self configFile close remove openForUpdating write(self config asJson)
    self)

  revertConfig := method(
    self configFile close remove openForUpdating write(self configBackup)
    self setConfig(Yajl parseJson(self configBackup)))
)

Eerie clone = Eerie do(
  doRelativeFile("Eerie/Package.io")
  doRelativeFile("Eerie/PackageDownloader.io")
  doRelativeFile("Eerie/PackageInstaller.io")
  doRelativeFile("Eerie/Env.io")

  init
)
