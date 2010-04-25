#!/usr/bin/env io

Importer addSearchPath("io/")
doFile("hooks/beforeInstall.io")

Eerie do(
  _log := getSlot("log")
  _allowedModes := list("info", "error", "transaction", "install")

  log = method(str, mode,
    (mode == nil or self _allowedModes contains(mode)) ifTrue(
      call delegateToMethod(self, "_log")))
)

Eerie Transaction clone\
  install(Eerie Package fromUri(Directory currentWorkingDirectory))\
  run

" --- Done! --- " println

