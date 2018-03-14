//metadoc Eerie category Utilites
//metadoc Eerie author Josip Lisec
//metadoc Eerie description Eerie is the package manager for Io.
SystemCommand

System userInterruptHandler := method(
    Eerie log("Reverting config before interrupt.")
    Eerie revertConfig
    Eerie Transaction releaseLock
)

Eerie := Object clone do(
  //doc Eerie root Value of EERIEDIR system's environment variable.
  root                ::= System getEnvironmentVariable("EERIEDIR")
  //doc Eerie ioHeadersPath Get path to Io's headers.
  ioHeadersPath       ::= root .. "/headers"
  //doc Eerie tmpDir Get path to temp directory.
  tmpDir              ::= root .. "/tmp"
  //doc Eerie usedEnv Environment currently in use, not necessarily same as [Eerie activeEnv](eerie.html#activeEnv).
  # usedEnv will be set from Eerie/Env.io
  usedEnv             ::= nil
  //doc Eerie activeEnv Default environment. You probably need [Eerie usedEnv](eerie.html#usedEnv).
  activeEnv           ::= nil
  configFile          :=  nil
  config              ::= nil
  configBackup        ::= nil
  //doc Eerie envs List of environmets
  envs                := List clone

  /*doc Eerie sh(cmd[, logFailure=true, dir=cwd])
  Executes system command. If logFailure is true and command exists with non-zero value application will abort.
  */
  sh := method(cmd, logFailure, dir,
      self log(cmd, "console")
      prevDir := nil
      dirPrefix := ""
      if(dir != nil and dir != ".",
          dirPrefix = "cd " .. dir .. " && "
          prevDir = Directory currentWorkingDirectory
          Directory setCurrentWorkingDirectory(dir)
      )

      cmdOut := System runCommand(dirPrefix .. cmd)
      stdOut := cmdOut stdout
      stdErr := cmdOut stderr

      prevDir isNil ifFalse(
          Directory setCurrentWorkingDirectory(prevDir)
      )

      # System runCommand leaves weird files behind
      System system(dirPrefix .. "rm -f *-stdout")
      System system(dirPrefix .. "rm -f *-stderr")

      if(cmdOut exitStatus != 0 and logFailure == true,
          self log("Last command exited with the following error:", "error")
          self log(stdOut, "error")
          self log(stdErr, "error")
          System exit(cmdOut exitStatus)
          ,
          return cmdOut exitStatus
      )
  )

  _logMods := Map with(
    "info",         " - ",
    "error",        " ! ",
    "console",      " > ",
    "debug",        " # ",
    "install",      " + ",
    "transaction",  "-> ",
    "output",       "")
  //doc Eerie log(message, mode) Displays the message to the user. Mode can be `"info"`, `"error"`, `"console"`, `"debug"` or `"output"`.
  log := method(str, mode,
    mode ifNil(mode = "info")
    ((self _logMods at(mode)) .. str) interpolate(call sender) println)

  init := method(
    self configFile := File with((self root) .. "/config.json") openForUpdating
    self setConfig(Yajl parseJson(self configFile contents))
    self setConfigBackup(self configFile contents)

    self config at("envs") ?foreach(name, envConfig,
      Eerie Env withConfig(name, envConfig)
    )

    activeEnv_ := self config at("activeEnv")
    activeEnv_ isNil ifFalse(
      self setActiveEnv(Eerie Env named(activeEnv_))
      self activeEnv use
    )

    self loadPlugins
    self
  )

  //doc Eerie updateConfig(key, value) Updates config Map.
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

  //doc Eerie loadPlugins Loads Eerie plugins.
  loadPlugins := method(
    self plugins := Object clone

    Eerie Env named("_plugins") ?packages ?foreach(pkg,
      self log("Loading #{pkg name} plugin", "debug")
      self plugins doFile(pkg path .. "/io/main.io")))
)

# Fixing Yajl's silent treatment of parse errors
Yajl do(
    _parseJson := getSlot("parseJson")
        parseJson = method(json,
            result := Yajl _parseJson(json)
            if(result type == "Error",
                Exception raise("Yajl: " .. result message),
                result
            )
        )
)

Eerie clone = Eerie do(
  //doc Eerie Exception [Exception](exception.html)
  doRelativeFile("Eerie/Exception.io")
  //doc Eerie Env [Env](env.html)
  doRelativeFile("Eerie/Env.io")
  //doc Eerie Package [Package](package.html)
  doRelativeFile("Eerie/Package.io")
  //doc Eerie PackageDownloader [PackageDownloader](packagedownloader.html)
  doRelativeFile("Eerie/PackageDownloader.io")
  //doc Eerie PackageInstaller [PackageInstaller](packageinstaller.html)
  doRelativeFile("Eerie/PackageInstaller.io")
  //doc Eerie Transaction [Transaction](transaction.html)
  doRelativeFile("Eerie/Transaction.io")
  //doc Eerie TransactionAction [TransactionAction](transactionaction.html)
  doRelativeFile("Eerie/TransactionAction.io")

  init
)
