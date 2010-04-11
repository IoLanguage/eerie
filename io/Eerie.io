//metadoc Eerie category Utilites
//metadoc Eerie author Josip Lisec
//metadoc Eerie description Eerie is the package manager for Io.
Eerie := Object clone do(
  //doc Eerie root Value of EERIEDIR system's environment variable.
  root                ::= System getEnvironmentVariable("EERIEDIR")
  //doc Eerie tmpDir
  tmpDir              ::= root .. "/tmp"
  //doc Eerie usedEnv Environment currently in use, not necessarily same as [[Eerie activeEnv]].
  # usedEnv will be set from Eerie/Env.io
  usedEnv             ::= nil
  //doc Eerie activeEnv Default environment. You probably need [[Eerie usedEnv]].
  activeEnv           ::= nil
  configFile          :=  nil
  config              ::= nil
  configBackup        ::= nil
  //doc Eerie envs List of environmets
  envs                := List clone

  //doc Eerie sh(cmd[, logFailure=true, dir=cwd]) Executes system command.
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
  //doc Eerie log(message, mode) Displays the message to the user, mode can be "info", "error", "console" or "output".
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

  //doc Eerie updateConfig(key, value) Updates config object.
  updateConfig := method(key, value,
    self config atPut(key, value)
    self saveConfig)

  //doc Eerie saveConfig
  saveConfig := method(
    self configFile close remove openForUpdating write(self config asJson)
    self)

  //doc Eerie revertConfig Reverts config to the state it was in before executing this script.
  revertConfig := method(
    self configFile close remove openForUpdating write(self configBackup)
    self setConfig(Yajl parseJson(self configBackup)))
)

Eerie clone = Eerie do(
  //doc Eerie Package [[Pacakge]]
  doRelativeFile("Eerie/Package.io")
  //doc Eerie PackageDownloader [[PackageDownloader]]
  doRelativeFile("Eerie/PackageDownloader.io")
  //doc Eerie PackageInstaller [[PackageInstaller]]
  doRelativeFile("Eerie/PackageInstaller.io")
  //doc Eerie Env [[Env]]
  doRelativeFile("Eerie/Env.io")

  init
)
