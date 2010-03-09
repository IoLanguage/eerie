#!/usr/bin/env io

Importer addSearchPath("io/")

Object clone do(
  setup := method(
    "---- Installing Eerie ----" println
    homeDir := User homeDirectory path
    eerieDir := homeDir .. "/.eerie"

    Directory with(eerieDir) exists ifTrue(
      " ! ~/.eerie directory already exists. Aborting installation." println
      System exit(1))

    bashFiles := list("bashrc", "profile", "bash_profile") map(f,
      Path with(homeDir, "/." .. f))

    bashScript := """

# Four Commandments of Eerie
EERIEDIR="#{eerieDir}"
IOIMPORT=$IOIMPORT:$EERIEDIR/activeEnv/protos
PATH=$PATH:$EERIEDIR/activeEnv/bin
export EERIEDIR IOIMPORT PATH

""" interpolate

    bashFiles foreach(path,
      f := File with(path) openForAppending
      f contents containsSeq("EERIEDIR") ifFalse(
        f appendToContents(bashScript))
      f close)

    " - Updated bash profile." println
    System setEnvironmentVariable("EERIEDIR", eerieDir)

    Directory with(eerieDir) create
    Directory with(eerieDir .. "/env") create

    #protosLoader := """AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/activeEnv/addons")"""
    #File with(eerieDir .. "/loader.io")   create openForUpdating write(protosLoader) close
    File with(eerieDir .. "/config.json") create openForUpdating write("{\"envs\": {}}") close

    Eerie Env with("base") create activate use
    Eerie Package with("Eerie", Directory currentWorkingDirectory) install
    " -.-" println
    " - Is there an eerie sound coming out of your basement?" println)
) setup
