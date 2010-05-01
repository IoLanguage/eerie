#!/usr/bin/env io

homePath  := User homeDirectory path
eeriePath := homePath .. "/.eerie"
eerieDir  := Directory with(eeriePath)

appendEnvVariables := method(
  System setEnvironmentVariable("EERIEDIR", eeriePath)

  # select() should eliminate symlinks
  bashFiles := list("bashrc", "profile", "bash_profile") map(f,
    Path with(homePath, "/." .. f)) select(p, File with(p) isRegularFile)

  bashScript := """|
    |# Four Commandments of Eerie
    |EERIEDIR=#{eeriePath}
    |PATH=$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin
    |export EERIEDIR PATH
    |# That's all folks""" fixMultiline interpolate

  bashFiles foreach(path,
    f := File with(path) openForAppending
    f contents containsSeq("EERIEDIR") ifFalse(
      f appendToContents(bashScript))
    f close))

appendAddonLoaderPaths := method(
  iorc := File with(homePath .. "/.iorc")
  iorc exists ifFalse(iorc create)
  loaderCode := """|
    |AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/base/addons")
    |AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/activeEnv)""" fixMultiline

  iorc openForAppending contents containsSeq("EERIEDIR") ifFalse(
    iorc appendToContents(loaderCode .. "\n"))
  iorc close)

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

Sequence fixMultiline := method(
  self splitNoEmpties("\n") map(split("|") last) join("\n") strip)

eerieDir exists ifFalse(
  appendEnvVariables
  appendAddonLoaderPaths
  createDirectories
  createDefaultEnvs)
