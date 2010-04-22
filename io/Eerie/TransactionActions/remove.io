Remove := Object clone do(
  prepare := method(true)

  execute := method(pkg,
    pkg runHook("beforeRemove")

    Directory with(pkg path .. "/bin") files foreach(f,
      File with("#{pkg env path}/bin/#{f name}" interpolate) remove)

    Eerie sh("rm -rf #{pkg path}" interpolate)
    pkg env removePackage(pkg)

    true)
)
