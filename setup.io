Importer addSearchPath("io/")

# Parse arguments

if(System args size > 4, 
    "Error: wrong number of arguments" println
    System exit(1))


options := System getOptions(System args)

(
    # check options
    availableOptions := list(System launchScript, "dev", "notouch", "shrc")

    options keys foreach(opt, 
        if(availableOptions contains(opt) not,
            "Error: unknown option \"#{opt}\"" interpolate println
            "Available options are:" println
            "\t--dev" println
            "\t--notouch" println
            "\t--shrc=<path>" println
            System exit(1)))
)

isDev := options hasKey("dev")

eeriePackageUrl := if(isDev,
    Directory currentWorkingDirectory,
    "https://github.com/IoLanguage/eerie.git")

isNotouch := options hasKey("notouch")

isWindows := (System platform containsAnyCaseSeq("windows") or(
    System platform containsAnyCaseSeq("mingw")))

shrc := block(
    if(options hasKey("shrc"), return list(options at("shrc")))

    if(isWindows,
        list(),
        list("~/.profile", "~/.bash_profile", "~/.zshrc"))
) call

eeriePath := if(isWindows, System installPrefix .. "\\eerie",
    ("~/.eerie" stringByExpandingTilde))

eerieDir := Directory with(eeriePath)

writePath := method(eeriePath,
    # we write eeriePath into a file and then read this file inside
    # install_unix.sh
    # this allows us to update current session with $EERIEDIR
    path := Directory currentWorkingDirectory .. "/__install_path"
    file := File with(path) create
    file setContents(eeriePath)
)

System setEnvironmentVariable("EERIEDIR", eeriePath)

System setEnvironmentVariable("PATH", 
    "#{System getEnvironmentVariable(\"PATH\")}:#{eeriePath}/base/bin:#{eeriePath}/activeEnv/bin" interpolate)

shellScript := """
# Eerie config
export EERIEDIR=#{eeriePath}
export PATH=$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin
# End Eerie config""" interpolate

appendEnvVariables := method(
    # just remind to setup variables if --notouch 
    if(isNotouch, 
        "----" println
        "Make sure to update your shell's environment variables before using Eerie." println
        "Here's a sample code you could use:" println
        shellScript println
        return)

    # add envvars to shell's configs
    shrc foreach(shfile,

        shfile := File with(shfile stringByExpandingTilde)
        shfile exists ifFalse(
            shfile create
            Eerie log("Created #{shfile path}"))

        shfile contents containsSeq("EERIEDIR") ifFalse(
            shfile appendToContents(shellScript)
            Eerie log("Added new environment variables to #{shfile path}")))

    # set envvars permanently on Windows
    if(isWindows and(shrc size == 0),
        Eerie sh("setx EERIEDIR #{eeriePath}" interpolate, true)
        Eerie sh("setx PATH \"%PATH%;#{eeriePath}\\base\\bin;#{eeriePath}\\activeEnv\\bin\"" \
            interpolate,
            true))
)

createDirectories := method(
    eerieDir createIfAbsent
    eerieDir directoryNamed("env") create
    eerieDir directoryNamed("tmp") create

    eerieDir fileNamed("/config.json") create \
        openForUpdating write("{\"envs\": {}}") close
)

createDefaultEnvs := method(
    baseEnv := Eerie Env with("_base") create activate use
    SystemCommand lnDirectory(baseEnv path, eeriePath .. "/base")

    Eerie Env with("_plugins") create
    Eerie Env with("default") create
    Eerie saveConfig
)

installEeriePkg := method(
    Eerie Transaction clone install(Eerie Package fromUri(eeriePackageUrl)) run
)

activateDefaultEnv := method(Eerie Env named("default") activate)

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
            call delegateToMethod(self, "_log"))
    )
)

createDefaultEnvs
installEeriePkg
appendEnvVariables
activateDefaultEnv
writePath(eeriePath)
" --- Done! --- " println
