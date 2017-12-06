//metadoc Env category Utilites
//metadoc Env description Reprsents an Eerie enveronment.

Env := Object clone do(
  //doc Env config
  config ::= nil

  //doc Env path Absolute path to the current environment directory.
  path := method(
    (Eerie root) .. "/env/" .. (self name))
  
  //doc Env name
  name := method(
    self config at("name"))

  //doc Env setName(name)
  setName := method(v,
    self config atPut("name", v)
    self)

  //doc Env addonsPath
  addonsPath := method(
    (self path) .. "/addons")

  init := method(
    self config := Map with(
      "name", nil,
      "packages", List clone)
    Eerie envs appendIfAbsent(self))

  //doc Env with(name) Creates new [[Env]] with provided name.
  with := method(name_,
    self clone setName(name_))

  //doc Env named(name) Looks for an environment with provided name. Returns that environment if found, <code>nil</code> otherwise.
  named := method(name_,
    Eerie envs detect(name == name_))

  //doc Env withConfig(name, config) Creates new environment with provided name and config map.
  withConfig := method(name_, config_,
    self clone setName(name_) setConfig(config_))

  //doc Env create Creates new environment, if it already exists an exception is thrown.
  create := method(
    root := Directory with((Eerie root) .. "/env/" .. (self name))
    root exists ifTrue(
      Eerie ExistingEnvException raise(self name))

    root create
    root createSubdirectory("bin")
    root createSubdirectory("addons")

    Eerie config at("envs") atPut(self name, self config)
    Eerie saveConfig

    self)

  //doc Env use Sets this environment as default one for current script.
  use := method(
    Eerie usedEnv isNil ifFalse(
      AddonLoader searchPaths remove(Eerie usedEnv path))

    Eerie setUsedEnv(self)
    AddonLoader appendSearchPath(self addonsPath)
    self)

  //doc Env activate Sets self as (global) default environment ([[Env use]] is not called).
  activate := method(
    Directory with((Eerie root) .. "/activeEnv") exists ifTrue(
      Eerie sh("rm #{Eerie root}/activeEnv" interpolate))
    Eerie updateConfig("activeEnv", self name)

    Eerie sh("ln -s #{self path} #{Eerie root}/activeEnv" interpolate)
    Eerie setActiveEnv(self)

    self)

  //doc Env remove Removes the environment.
  remove := method(
    Eerie config at("envs") removeAt(self name)
    Eerie saveConfig
    Eerie envs remove(self)

    Eerie sh("rm -rf #{self path}" interpolate)
    true)

  //doc Env isActive
  isActive := method(
    Eerie activeEnv == self)

  //doc Env isUsed
  isUsed := method(
    Eerie usedEnv == self)

  //doc Env packages Returns list of packages installed in this environment.
  packages := method(
    self packages = self config at("packages") map(pkgConfig,
      (pkgConfig type == "Map") ifFalse(
        pkgConfig = Yajl parseJson(pkgConfig))

      Eerie Package withConfig(pkgConfig, self)))

  //doc Env packageNamed(name) Returns package with provided name if it exists, <code>nil</code> otherwise.
  packageNamed := method(pkgName,
    self packages detect(pkg, pkg name == pkgName))

  //doc Env appendPackage(package) Saves package's configuration into own configuration.
  appendPackage := method(package,
    self config at("packages") appendIfAbsent(package config)
    self packages appendIfAbsent(package)
    Eerie saveConfig

    self)

  //doc Env removePackage(package)
  removePackage := method(package,
    self config at("packages") remove(package config)
    self packages remove(package)
    Eerie saveConfig

    self)
    
  //doc Env updatePackage(package)
  updatePackage := method(package,
    self config at("packages") detect(name == package name) isNil ifTrue(
      Eerie log("Tried to update package which is not yet installed. (#{self name}/#{package name})", "debug")
      return(false))

    self config at("packages") removeAt(package name) atPut(package name, package config)
    self packages remove(old) append(package)
    Eerie saveConfig

    self)

  //doc Env asJson Returns configuration.
  asJson    := method(self config)
)
