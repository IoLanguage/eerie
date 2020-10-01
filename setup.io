#!/usr/local/bin io

Importer addSearchPath("io/")

# Parse arguments

if(System args size > 4, 
        "Error: wrong number of arguments" println
        System exit(1))

options := System getOptions(System args)

isDev := options hasKey("dev")

eeriePackageUrl := if(isDev,
        Directory currentWorkingDirectory,
        "https://github.com/IoLanguage/eerie.git")

isNotouch := options hasKey("notouch")

shrc := block(
        if(options hasKey("shrc"), return list(options at("shrc")))

        if(System platform containsAnyCaseSeq("windows") 
            or(System platform containsAnyCaseSeq("mingw")),
            list(),
            list( "~/.profile", "~/.bash_profile", "~/.zshrc"))
        ) call

eeriePath := block(
    platform := System platform
    if(platform containsAnyCaseSeq("windows")
        or(platform containsAnyCaseSeq("mingw")),
        return System installPrefix .. "/eerie"
        ,
        return ("~/.eerie" stringByExpandingTilde)
      )
) call

eerieDir := Directory with(eeriePath)

System setEnvironmentVariable("EERIEDIR", eeriePath)
System setEnvironmentVariable("PATH", 
        "#{System getEnvironmentVariable(\"PATH\")}:#{eeriePath}/base/bin:#{eeriePath}/activeEnv/bin" interpolate)

shellScript := """
# Eerie config
EERIEDIR=#{eeriePath}
PATH=$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin
export EERIEDIR PATH
# End Eerie config""" interpolate

appendEnvVariables := method(
        if(isNotouch or(shrc size == 0), 
            "----" println
            "Make sure to update your shell's environment variables before using Eerie." println
            "Here's a sample code you could use:" println
            shellScript println
            return)

        shrc foreach(shfile,

            shfile := File with(shfile stringByExpandingTilde)
            shfile exists ifFalse(
                shfile create
                Eerie log("Created #{shfile path}"))

            shfile contents containsSeq("EERIEDIR") ifFalse(
                shfile appendToContents(shellScript)
                Eerie log("Added new environment variables to #{shfile path}")
                )
            )
)

createDirectories := method(
  eerieDir createIfAbsent
  eerieDir directoryNamed("env") create
  eerieDir directoryNamed("tmp") create

  eerieDir fileNamed("/config.json") create openForUpdating write("{\"envs\": {}}") close
)

createDefaultEnvs := method(
  baseEnv := Eerie Env with("_base") create activate use
  SystemCommand lnDirectory(baseEnv path, eeriePath .. "/base")

  Eerie Env with("_plugins") create
  Eerie Env with("default") create
  Eerie saveConfig)

installEeriePkg := method(
  Eerie Transaction clone install(Eerie Package fromUri(eeriePackageUrl)) run
)

activateDefaultEnv := method(
  Eerie Env named("default") activate)

# Run the process
if(eerieDir exists,
        "Error: Eerie is already installed at #{eerieDir path}" interpolate println
        System exit(1))

createDirectories

Eerie do(
        _log := getSlot("log")
        _allowedModes := list("info", "error", "transaction", "install")

        log = method(str, mode,
            (mode == nil or self _allowedModes contains(mode)) ifTrue(
                call delegateToMethod(self, "_log")
                )
            )
        )

createDefaultEnvs
installEeriePkg
appendEnvVariables
activateDefaultEnv
" --- Done! --- " println
