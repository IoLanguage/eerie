#!/usr/bin/env io

Importer addSearchPath("io/")

homePath  := User homeDirectory path
eeriePath := homePath .. "/.eerie"
eerieDir  := Directory with(eeriePath)

System setEnvironmentVariable("EERIEDIR", eeriePath)

appendEnvVariables := method(
  bashScript := """|
    |# Eerie config
    |EERIEDIR=#{eeriePath}
    |PATH=$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin
    |export EERIEDIR PATH
    |# End Eerie config""" fixMultiline interpolate
  bashFile := System args at(1)

  if(bashFile,
    bashFile = File with(bashFile)
    bashFile exists ifFalse(
      bashFile create
      Eerie log("Created #{bashFile path}"))
    
    bashFile contents containsSeq("EERIEDIR") ifFalse(
      bashFile appendToContents(bashScript)
      Eerie log("Added new environment variables to #{bashFile path}")
      Eerie log("Make sure to run \"source #{bashFile path}\""))
  ,
    "----" println
    "Make sure to update your shell's environment variables before using Eerie." println
    "Here's a sample code you could use:" println
    bashScript println))

appendAddonLoaderPaths := method(
  iorc := File with(homePath .. "/.iorc")
  iorc exists ifFalse(iorc create)
  loaderCode := """|
    |AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/base/addons")
    |AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/activeEnv/addons")""" fixMultiline

  iorc openForAppending contents containsSeq("EERIEDIR") ifFalse(
    iorc appendToContents(loaderCode .. "\n"))
  iorc close
  " - Updated ~/.iorc file" println)

createDirectories := method(
  eerieDir create
  eerieDir directoryNamed("env") create
  eerieDir directoryNamed("tmp") create

  eerieDir fileNamed("/config.json")\
    create openForUpdating write("{\"envs\": {}}") close)

createDefaultEnvs := method(
  baseEnv := Eerie Env with("_base") create activate use
  Eerie sh("ln -s #{baseEnv path} #{eeriePath}/base" interpolate)

  Eerie Env with("_plugins") create
  Eerie Env with("default") create
  Eerie saveConfig)

installEeriePkg := method(
  Eerie Transaction clone\
    install(Eerie Package fromUri("git://github.com/josip/eerie.git"))\
    run)

activateDefaultEnv := method(
  Eerie Env named("default") activate)

Sequence fixMultiline := method(
  self splitNoEmpties("\n") map(split("|") last) join("\n") strip)

eerieDir exists ifFalse(
  appendAddonLoaderPaths
  createDirectories

  Eerie do(
    _log := getSlot("log")
    _allowedModes := list("info", "error", "transaction", "install")

    log = method(str, mode,
      (mode == nil or self _allowedModes contains(mode)) ifTrue(
        call delegateToMethod(self, "_log")))
  )
  
  createDefaultEnvs
  installEeriePkg
  appendEnvVariables
  activateDefaultEnv
  " --- Done! --- " println)
