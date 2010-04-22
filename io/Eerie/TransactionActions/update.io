Update := Object clone do(
  prepare := method(pkg,
    hasUpdates := pkg downloader hasUpdates
    if(hasUpdates,
      Eerie Transaction install(pkg))
    hasUpdates)

  execute := method(pkg,
    pkg runHook("beforeUpdate")
    pkg downloader update
    pkg runHook("afterUpdate")
    pkg loadInfo

    true)
)