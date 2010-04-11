Package := Object clone do(
  //doc Package config
  config ::= nil

  //doc Package name
  name := method(
    self config at("name"))

  //doc Package setName(name)
  setName := method(v,
    self config atPut("name", v)
    self)

  //doc Package uri
  uri := method(
    self config at("uri"))

  //doc Package setUri
  setUri := method(v,
    self config atPut("uri", v)
    self)

  //doc Package path
  path := method(
    self config at("path"))

  //doc Package setPath(path)
  setPath := method(v,
    self config atPut("path", v)
    self)

  //doc Package installer Instace of [[PackageInstaller]] for this package.
  installer ::= nil
  //doc Package downloader Instance of [[PackageDownloader]] for this package.
  downloader ::= nil

  init := method(
    self config = Map with(
      "name", nil,
      "uri",  nil,
      "path", nil,
      "meta", Map clone))

  //doc Package with(name, uri) Creates new package with provided name and URI.
  with := method(name_, uri_,
    (uri_ exSlice(-1) == "/") ifTrue(
      uri_ = uri_ exSlice(0, -1))

    self clone setConfig(Map with(
      "name", name_,
      "uri",  uri_,
      "path", (Eerie usedEnv path) .. "/addons/" .. name_)))

  //doc Package withConfig(config) Creates new package from provided config Map.
  withConfig := method(config,
    klone := self clone setConfig(config)
    klone config at("installer") isNil ifFalse(
      klone installer = Eerie PackageInstaller instances getSlot(klone config at("installer"))
      klone installer = klone installer with(klone config at("path")))
    klone config at("downloader") isNil ifFalse(
      klone downloader = Eerie PackageDownloader instances getSlot(klone config at("downloader"))
      klone downloader = klone downloader with(klone config at("uri"), klone config at("path")))

    klone)

  //doc Package fromUri(uri) Creates new package from provided uri. Name is determined with [[Package guessName]].
  fromUri := method(uri_,
    self with(self guessName(uri_), uri_))

  //doc Package guessName(uri) Guesses name from provide URI. Usually it is just file's basename.
  guessName := method(uri_,
    (uri_ exSlice(-1) == "/") ifTrue(
      uri_ = uri_ exSlice(0, -1))

    f := File with(uri_)
    # We can't use baseName here because it returns nil for directories
    if(f exists,
      f name split("."),
      uri_ split("/") last split(".")) first makeFirstCharacterUppercase)

  //doc Package setInstaller(packageInstaller)
  setInstaller := method(inst,
    self installer = inst
    self config atPut("installer", inst type)
    self)

  //doc Package setDownloader(packageDownloader)
  setDownloader := method(downl,
    self downloader := downl
    self config atPut("downloader", downl type)
    self)

  //doc Package install([isUpdate]) Downloads and then installs the package. Runs before/after Install/Update hooks.
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
    Eerie usedEnv appendPackage(self)

    self runHook("after" .. event)
    self)

  //doc Package installDependencies Installed package's dependencies.
  installDependencies := method(
    deps := self dependencies("packages")
    deps foreach(_uri,
      self fromUri(_uri) install))

  //doc Package update Updates the package if necessary. Runs before/after UpdateDownload hooks.
  update := method(
    self runHook("beforeUpdateDownload")
    shouldUpdate := self downloader update
    self runHook("afterUpdateDownload")
    shouldUpdate ifTrue(
      self install(true)))

  //doc Package remove Removes (uninstalls) the package. Runs beforeRemove hook
  remove := method(
    self runHook("beforeRemove")

    Directory with(self path .. "/bin") files foreach(f,
      File with("#{Eerie usedEnv path}/bin/#{f name}" interpolate) remove)

    #Directory with(self path) remove
    Eerie sh("rm -rf #{self path}" interpolate)
    Eerie usedEnv removePackage(self)

    true)

  //doc Package runHook(hookName) Runs Io script with hookName in package's <code>hooks<code> directory if it exists.
  runHook := method(hook,
    f := File with("#{self path}/hooks/#{hook}.io" interpolate)
    f exists ifTrue(
      Eerie log("Launching #{hook} hook for #{self name}", "debug")
      try(Thread createThread(f contents))
      f close))

  //doc Package loadMetadata Loads package.json file.
  loadMetadata := method(
    meta := File with((self path) .. "/package.json")
    meta exists ifTrue(
      self config atPut("meta", Yajl parseJson(meta openForReading contents))
      meta close))

  //doc Package providesProtos Returns list of protos this package provides.
  providesProtos := method(
    p := self config at("meta") ?at("protos")
    if(p isNil, list(), p))

  //doc Package dependencies([category]) Returns list of dependencies this package has. <code>category</code> can be <code>protos</code>, <code>packages</code>, <code>headers</code> or <code>libs</code>.
  dependencies := method(category,
    d := self config at("meta") ?at("dependencies")
    if(category and d and d isEmpty not, d = d at(category))
    if(d isNil, list(), d))

  //doc Package asJson Returns config.
  asJson := method(
    self config)
)
