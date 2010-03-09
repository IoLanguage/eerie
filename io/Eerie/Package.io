Package := Object clone do(
  config ::= nil
  
  name := method(
    self config at("name"))
  
  setName := method(v,
    self config atPut("name", v)
    self)

  uri := method(
    self config at("uri"))
  
  setUri := method(v,
    self config atPut("uri", v)
    self)

  path := method(
    self config at("path"))

  setPath := method(v,
    self config atPut("path", v)
    self)

  installer ::= nil
  downloader ::= nil

  init := method(
    self config = Map with(
      "name", nil,
      "uri",  nil,
      "path", nil,
      "meta", Map clone))
  
  with := method(_name, _uri,
    self clone setConfig(Map with(
      "name", _name,
      "uri", _uri,
      "path", (Eerie activeEnv path) .. "/addons/" .. _name)))

  withConfig := method(config,
    self clone setConfig(config))

  setInstaller := method(inst,
    self installer = inst
    self config atPut("installer", inst type)
    self)

  setDownloader := method(downl,
    self downloader := downl
    self config atPut("downloader", downl type)
    self)

  install := method(isUpdate,
    (isUpdate != true) ifTrue(
      Directory with(self path) exists ifTrue(
        Exception raise("Package #{self name} is already installed." interpolate)))

    event := if(isUpdate, "Update", "Install")
    Eerie log("#{event}ing '#{self name}' from #{self uri}...")
    self runHook("before" .. event)

    Directory with(self path) createIfAbsent
    self setDownloader(Eerie PackageDownloader detect(self uri, self path))
    self downloader download
    
    self loadMetadata
    self dependencies ?isEmpty ifFalse(
       self installDependencies)

    self setInstaller(Eerie PackageInstaller detect(self path))
    self installer install

    self loadMetadata
    Eerie activeEnv registerPackage(self)

    self runHook("after" .. event))

  installDependencies := method(
    Eerie log("Installing depenendencies"))

  update := method(
    self runHook("beforeUpdateDownload")
    self downloader update
    self runHook("afterUpdateDownload")

    self install(true))

  remove := method(
    self runHook("beforeRemove")

    Directory with(self path .. "/bin") files foreach(f,
      File with("#{Eerie activeEnv path}/bin/#{f name}" interpolate) remove)

    Directory with(self path) remove
    Eerie config at(Eerie activeEnv name) at("packages") removeAt(self name)
    Eerie saveConfig

    true)

  runHook := method(hook,
    f := File with("#{self path}/hooks/#{hook}.io")
    f exists ifTrue(
      try(
        Thread createThread(f contents))
      f close))
      
  loadMetadata := method(
    meta := File with((self path) .. "/package.json")
    meta exists ifTrue(
      self config atPut("meta", Yajl parseJson(meta openForReading contents))
      meta close))

  providesProtos := method(
    p := self config at("meta") ?at("protos")
    if(p isNil, list(), p))

  dependencies := method(
    d := self config at("meta") ?at("dependencies")
    if(d isNil, list(), d))

  asJson := method(
    self config asJson)
)