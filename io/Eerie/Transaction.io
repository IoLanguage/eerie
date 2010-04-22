Transaction := Object clone do(
  items         := List clone
  depsCheckedFor  := List clone
  
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
    if(self lockFile openForReading contents == System thisProcessPid asString,
      self lockFile close remove
      true))

  hasLock := method(
    self lockFile exists ifFalse(return(false))
    self lockFile contents == System thisProcessPid asString)

  //doc Transaction begin
  begin := method(
    self acquireLock
    self items = List clone
    self depsCheckedFor = List clone
    self)

  //doc Transaction run
  run := method(
    self items = self items select(action,
      pkg := action second
      Eerie log("Preparing #{action first} for #{pkg name}...")
      self actions getSlot(action first) prepare(pkg) ifTrue(
        self resolveDeps(pkg)))

    self items reverse foreach(action,
      pkg := action second
      Eerie log("#{action first}ing #{pkg name}...")
      self actions getSlot(action first) execute(pkg))

    self releaseLock)

  //doc Transaction actsUpon(package)
  actsUpon := method(package,
    uri := package uri
    self items detect(act, act second uri == uri) != nil)

  //doc Transaction addAction(actionName, package)
  addAction := method(action, pkg,
    self items contains(list(action, pkg)) ifFalse(
      self actions hasLocalSlot(action) ifFalse(
        Exception raise("unknownTransactionAction", action))
      self items append(list(action, pkg)))
    self)

  install := method(package,
    self addAction("Install", package))

  update := method(package,
    self addAction("Update",  package))
  
  remove := method(package,
    self addAction("Remove", package))

  resolveDeps := method(package,
    Eerie log("Resolving dependencies for #{package name}")
    deps := package info at("dependencies")
    if(deps == nil or deps keys isEmpty,
      return(true))

    toInstall := list()
    deps at("packages") ?foreach(uri,
      self depsCheckedFor contains(uri) ifTrue(continue)
      if(Eerie usedEnv packages detect(pkg, pkg uri == uri) isNil,
        toInstall appendIfAbsent(Eerie Package fromUri(uri))))

    deps at("protos") ?foreach(protoName,
      AddonLoader hasAddonNamed(protoName) ifFalse(
        Exception raise("missingProto", list(package name, protoName))))

    self depsCheckedFor append(package uri)
    Eerie log("Missing pkgs: #{toInstall map(name)}", "debug")
    toInstall foreach(pkg, install(pkg))
    self)
)
Transaction clone = Transaction

Transaction actions := Object clone do(
  doRelativeFile("TransactionActions/install.io")
  doRelativeFile("TransactionActions/update.io")
  doRelativeFile("TransactionActions/remove.io")
)
