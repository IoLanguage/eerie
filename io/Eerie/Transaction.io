Transaction := Object clone do(
  items         := List clone
  depsCheckedFor  := List clone

  init := method(
    self items = List clone
    self depsCheckedFor = List clone
    self acquireLock)
 
  lockFile := File with(Eerie root .. "/.transaction_lock")

  //doc Transaction acquireLock
  acquireLock := method(
    processPid := if(lockFile exists, lockFile openForReading contents, nil)
    if(processPid == System thisProcessPid asString,
      Eerie log("Trying to acquire lock but its already present.", "debug")
      return(true))

    while(self lockFile exists,
      Eerie log("[#{Date now}] Process #{processPid} has lock. Waiting for process to finish...", "error")
      System sleep(5))

    self lockFile close openForUpdating write(System thisProcessPid asString) close
    true)

  //doc Tranasction releaseLock
  releaseLock := method(
    self lockFile exists ifFalse(
      return(true))

    if(self lockFile openForReading contents == System thisProcessPid asString,
      self lockFile close remove
      true))
      
  //doc Transaction hasLock
  hasLock := method(
    self lockFile exists ifFalse(return(false))
    self lockFile contents == System thisProcessPid asString)

  //doc Transaction run
  run := method(
    self items isEmpty ifTrue(
      return(self releaseLock))

    self items = self items select(action,
      #Eerie log("Preparing #{action name} for #{action pkg uri}...")
      action prepare ifTrue(
        self resolveDeps(action pkg)))

    self items reverse foreach(action,
      Eerie log("#{action asVerb} #{action pkg name}...")
      action execute)

    self releaseLock)

  //doc Transaction actsUpon(package)
  actsUpon := method(package,
    uri := package uri
    self items detect(act, act second uri == uri) != nil)

  //doc Transaction addAction(actionName, package)
  addAction := method(action,
    self items contains(action) ifFalse(
      Eerie log("#{action name} #{action pkg name}", "transaction")
      self items append(action))
    self)

  install := method(package,
    self addAction(Eerie TransactionAction named("Install") with(package)))

  update := method(package,
    self addAction(Eerie TransactionAction named("Update") with(package)))

  remove := method(package,
    self addAction(Eerie TransactionAction named("Remove") with(package)))

  resolveDeps := method(package,
    Eerie log("Resolving dependencies for #{package name}")
    deps := package info at("dependencies")
    if(deps == nil or deps ?keys ?isEmpty,
      return(true))

    # TODO: Check if all dependencies are actually satisfied before
    # installing them
    toInstall := list()
    deps at("packages") ?foreach(uri,
      self depsCheckedFor contains(uri) ifTrue(continue)
      if(Eerie usedEnv packages detect(pkg, pkg uri == uri) isNil,
        toInstall appendIfAbsent(Eerie Package fromUri(uri))))

    deps at("protos") ?foreach(protoName,
      AddonLoader hasAddonNamed(protoName) ifFalse(
        Eerie MissingProtoException raise(list(package name, protoName))))

    self depsCheckedFor append(package uri)
    Eerie log("Missing pkgs: #{toInstall map(name)}", "debug")
    toInstall foreach(pkg, Eerie Transaction clone install(pkg) run)
    true)
)


