Env := Object clone do(
  config ::= nil

  path := method(
    (Eerie root) .. "/env/" .. (self name))
  
  name := method(
    self config at("name"))

  setName := method(v,
    self config atPut("name", v)
    self)

  addonsPath := method(
    (self path) .. "/addons")

  init := method(
    self config := Map with(
      "name", nil,
      "packages", List clone)
    Eerie envs appendIfAbsent(self))

  with := method(name_,
    self clone setName(name_))

  named := method(name_,
    Eerie envs detect(name == name_))

  withConfig := method(name_, config_,
    self clone setName(name_) setConfig(config_))

  create := method(
    root := Directory with((Eerie root) .. "/env/" .. (self name))
    root exists ifTrue(
      Exception raise("Environment '#{self name}' already exists." interpolate))

    root create
    root createSubdirectory("bin")
    root createSubdirectory("addons")

    Eerie config at("envs") atPut(self name, self config)
    Eerie saveConfig

    self)

  use := method(
    Eerie activeEnv isNil ifFalse(
      AddonLoader searchPaths remove(Eerie activeEnv path))

    Eerie setActiveEnv(self)
    AddonLoader appendSearchPath(self addonsPath)
    self)

  activate := method(
    Eerie updateConfig("activeEnv", self name)
    Directory with((Eerie root) .. "/activeEnv") exists ifTrue(
      Eerie sh("rm #{Eerie root}/activeEnv" interpolate))

    Eerie sh("ln -s #{self path} #{Eerie root}/activeEnv" interpolate)

    self)

  remove := method(
    Eerie config at("envs") removeAt(self name)
    Eerie saveConfig
    Eerie envs remove(self)

    Eerie sh("rm -rf #{self path}" interpolate)
    true)

  isActive := method(
    Eerie activeEnv == self)

  packages := method(
    self packages = self config at("packages") map(pkgConfig,
      (pkgConfig type == "Map") ifFalse(
        pkgConfig = Yajl parseJson(pkgConfig))

      Eerie Package withConfig(pkgConfig)))

  packageNamed := method(pkgName,
    self packages detect(pkg, pkg name == pkgName))

  registerPackage := method(package,
    self config at("packages") appendIfAbsent(package asJson)
    self packages appendIfAbsent(package)
    Eerie saveConfig

    self)

  removePackage := method(package,
    "removePackage" println)

  asJson    := method(self config)
)
