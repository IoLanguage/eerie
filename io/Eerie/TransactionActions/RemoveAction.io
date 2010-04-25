RemoveAction := Eerie TransactionAction clone do(
  name := "Remove"
  asVerb := "Removing"

  prepare := method(true)

  execute := method(
    self pkg runHook("beforeRemove")

    Directory with(self pkg path .. "/bin") files foreach(f,
      File with("#{self pkg env path}/bin/#{f name}" interpolate) remove)

    Eerie sh("rm -rf #{self pkg path}" interpolate)
    self pkg env removePackage(self pkg)

    true)
)
