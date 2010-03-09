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

  with := method(_name,
    self clone setName(_name))
  
  named := method(_name,
    Eerie envs detect(name == _name))

  withConfig := method(_name, _config,
    self clone setName(_name) setConfig(_config))

  create := method(
    root := Directory with((Eerie root) .. "/env/" .. (self name))
    root exists ifTrue(
      Exception raise("Environment '#{self name}' already exists." interpolate))

    root create
    root createSubdirectory("bin")
    root createSubdirectory("addons")
    root createSubdirectory("protos")

    Eerie config at("envs") atPut(self name, self config)
    Eerie saveConfig
    Eerie log("Created #{self name} env.")

    self)

  use := method(
    Eerie log("Using #{self name} env.")
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
      Eerie Package withConfig(pkgConfig)))

  registerPackage := method(package,
    self config at("packages") appendIfAbsent(package asJson)
    self packages appendIfAbsent(package)
    Eerie saveConfig

    package providesProtos foreach(providedProto,
      l := """
AddonLoader appendSearchPath(System getEnvironmentVariable("EERIEDIR") .. "/env/#{self name}/addons")
AddonLoader loadAddonNamed("#{providedProto}")
""" interpolate
      File with("#{self path}/protos/#{providedProto}.io" interpolate) create openForUpdating write(l) close)

    Eerie log("Installed package #{package name}.")
    self)
  
  removePackage := method(package,
    "removePackage" println)

  asString  := method(self name)
  asJson    := method(self name asJson)
)
