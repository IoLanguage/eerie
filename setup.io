#!/usr/bin/env io

Importer addSearchPath("io/")

Object clone do(
  setup := method(
    "---- Installing Eerie ----" println
    homePath := User homeDirectory path
    eeriePath := homePath .. "/.eerie"
    eerieDir := Directory with(eeriePath)

    eerieDir exists ifTrue(
      " ! ~/.eerie directory already exists. Aborting installation." println
      System exit(1))

    bashFiles := list("bashrc", "profile", "bash_profile") map(f,
      Path with(homePath, "/." .. f))

    bashScript := """

# Four Commandments of Eerie
EERIEDIR=#{eeriePath}
PATH=$PATH:$EERIEDIR/activeEnv/bin:$EERIEDIR/base/bin
export EERIEDIR PATH
# That's all folks

""" interpolate

    bashFiles foreach(path,
      f := File with(path) openForAppending
      f contents containsSeq("EERIEDIR") ifFalse(
        f appendToContents(bashScript))
      f close)

    " - Updated bash profile." println

    iorc := File with(homePath .. "/.iorc")
    iorc exists ifFalse(iorc create)
    loaderCode := """
AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/base/addons")
AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/activeEnv/addons")
"""
    iorc openForAppending contents containsSeq("EERIEDIR") ifFalse(
      iorc appendToContents(loaderCode .. "\n"))
    iorc close
    " - Updated iorc file." println

    System setEnvironmentVariable("EERIEDIR", eeriePath)

    eerieDir create
    eerieDir directoryNamed("env") create
    eerieDir directoryNamed("tmp") create

    eerieDir fileNamed("/config.json") create openForUpdating write("{\"envs\": {}}") close

    baseEnv := Eerie Env with("_base") create activate use
    Eerie sh("ln -s #{baseEnv path} #{eeriePath}/base" interpolate)

    # This will allow Eerie to update itself.
    Eerie Package fromUri("git://github.com/josip/eerie.git") install
    Eerie saveConfig

    Eerie Env with("default") create activate use

    " ---- Fin ----" println
    System sleep(1)
    " - Oh, wait, is there an eerie sound coming out of your basement?" println)
) setup
