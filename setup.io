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
#IOIMPORT=$IOIMPORT:$EERIEDIR/activeEnv/protos
PATH=$PATH:$EERIEDIR/activeEnv/bin
export EERIEDIR PATH
# That's all folks

""" interpolate

    bashFiles foreach(path,
      f := File with(path) openForAppending
      f contents containsSeq("EERIEDIR") ifFalse(
        f appendToContents(bashScript))
      f close)

    " - Updated bash profile." println

    iorc := File with(homeDir .. "/.iorc")
    iorc exists ifFalse(iorc create)
    loaderCode := """AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/activeEnv/addons")"""
    iorc openForAppending contents containsSeq("EERIEDIR") ifFalse(
      iorc appendToContents(loaderCode .. "\n"))
    iorc close
    " - Updated iorc file." println

    System setEnvironmentVariable("EERIEDIR", eerieDir)

    Directory with(eerieDir) create
    Directory with(eerieDir .. "/env") create

    File with(eerieDir .. "/config.json") create openForUpdating write("{\"envs\": {}}") close

    Eerie Env with("base") create activate use
    Eerie Package with("Eerie", Directory currentWorkingDirectory) install
    " ---- Fin ----" println
    System sleep(1)
    " - Oh, wait, is there an eerie sound coming out of your basement?" println)
) setup
