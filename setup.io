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
EERIEDIR=#{eerieDir}
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

    iorc := File with(homeDir .. "/.iorc")
    iorc exists ifFalse(iorc create)
    loaderCode := """
AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/base/addons")
AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/activeEnv/addons")
"""
    iorc openForAppending contents containsSeq("EERIEDIR") ifFalse(
      iorc appendToContents(loaderCode .. "\n"))
    iorc close
    " - Updated iorc file." println

    System setEnvironmentVariable("EERIEDIR", eerieDir)

    Directory with(eerieDir) create
    Directory with(eerieDir .. "/env") create

    File with(eerieDir .. "/config.json") create openForUpdating write("{\"envs\": {}}") close

    baseEnv := Eerie Env with("_base") create activate use
    Eerie sh("ln -s #{baseEnv path} #{eerieDir}/base" interpolate)

    eeriePkg := Eerie Package fromUri(Directory currentWorkingDirectory) install
    # This will allow Eerie to update itself.
    eeriePkg setUri("git://github.com/josip/Eerie.git")
    eeriePkg setDownloader(Eerie PackageDownloader instances VcsDownloader)
    Eerie saveConfig

    Eerie Env with("default") create activate use

    " ---- Fin ----" println
    System sleep(1)
    " - Oh, wait, is there an eerie sound coming out of your basement?" println)
) setup
