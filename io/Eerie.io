Eerie := Object clone do(
  root                ::= System getEnvironmentVariable("EERIEDIR")
  # activeEnv will be set from Eerie/Env.io
  activeEnv           ::= nil
  configFile          :=  nil
  config              ::= nil
  envs                := List clone

  sh := method(cmd, logFailure,
    self log(cmd, "console")
    cmdOut := System runCommand(cmd)

    if(cmdOut exitStatus != 0,
      if(logFailure == false,
        false
      ,
        self log("Last command exited with the following error:", "error")
        self log(cmdOut stdout, "output")
        self log(cmdOut stderr, "output")
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

    self config at("envs") ?foreach(name, envConfig,
      Eerie Env withConfig(name, envConfig))

    _activeEnv := self config at("activeEnv")
    _activeEnv isNil ifFalse(
      self setActiveEnv(Eerie Env named(_activeEnv))
      self activeEnv use)
    self)

  updateConfig := method(key, value,
    self config atPut(key, value)
    self saveConfig)

  saveConfig := method(
    self configFile close remove openForUpdating write(self config asJson)
    self)
)

Eerie clone = Eerie do(
  doRelativeFile("Eerie/Package.io")
  doRelativeFile("Eerie/PackageDownloader.io")
  doRelativeFile("Eerie/PackageInstaller.io")
  doRelativeFile("Eerie/Env.io")
  
  init
)
