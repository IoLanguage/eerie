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
  
  with := method(name_, uri_,
    self clone setConfig(Map with(
      "name", name_,
      "uri",  uri_,
      "path", (Eerie activeEnv path) .. "/addons/" .. name_)))

  withConfig := method(config,
    klone := self clone setConfig(config)
    klone config at("installer") isNil ifFalse(
      klone installer = Eerie PackageInstaller instances getSlot(klone config at("installer"))
      klone installer = klone installer with(klone config at("path")))
    klone config at("downloader") isNil ifFalse(
      klone downloader = Eerie PackageDownloader instances getSlot(klone config at("downloader"))
      klone downloader = klone downloader with(klone config at("uri"), klone config at("path")))

    klone)

  fromUri := method(path_,
    self with(self guessName(path_), path_))

  guessName := method(uri_,
    (uri_ exSlice(-1) == "/") ifTrue(
      uri_ = uri_ exSlice(0, -1))
    
    f := File with(uri_)
    if(f exists,
      # We can't use baseName here because it returns nil for directories
      f name split(".") first makeFirstCharacterUppercase,
      uri_ split("/") last split(".") first makeFirstCharacterUppercase))

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
    self runHook("before" .. event)

    isUpdate not ifTrue(
      Directory with(self path) createIfAbsent
      self setDownloader(Eerie PackageDownloader detect(self uri, self path))
      self downloader download)

    self setInstaller(Eerie PackageInstaller detect(self path))
    self installer loadConfig
    self loadMetadata

    self installDependencies
    self installer install

    self loadMetadata
    Eerie activeEnv registerPackage(self)

    self runHook("after" .. event)
    self)

  installDependencies := method(
    deps := self dependencies("packages")
    deps foreach(_uri,
      self fromUri(_uri) install))

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
    f := File with("#{self path}/hooks/#{hook}.io" interpolate)
    f exists ifTrue(
      try(Thread createThread(f contents))
      f close))

  loadMetadata := method(
    meta := File with((self path) .. "/package.json")
    meta exists ifTrue(
      self config atPut("meta", Yajl parseJson(meta openForReading contents))
      meta close))

  providesProtos := method(
    p := self config at("meta") ?at("protos")
    if(p isNil, list(), p))

  dependencies := method(category,
    d := self config at("meta") ?at("dependencies")
    if(category and d and d isEmpty not, d = d at(category))
    if(d isNil, list(), d))

  asJson := method(
    self config)
)