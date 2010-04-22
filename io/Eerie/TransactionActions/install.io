Install := Object clone do(
  prepare := method(pkg,
    Directory with(pkg path) create

    pkg downloader isNil ifTrue(
      pkg setDownloader(Eerie PackageDownloader detect(pkg uri, pkg path)))

    pkg runHook("beforeDownload")
    pkg downloader download
    pkg runHook("afterDownload")

    true)

  execute := method(pkg,
    pkg installer isNil ifTrue(
      pkg setInstaller(Eerie PackageInstaller detect(pkg path)))

    pkg runHook("beforeInstall")
    pkg installer install
    pkg env appendPackage(pkg)
    pkg runHook("afterInstall")

    pkg loadInfo
    true)
)
