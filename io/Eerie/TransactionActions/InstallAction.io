InstallAction := Eerie TransactionAction clone do(
  asVerb := "Installing"

  prepare := method(
    Directory with(self pkg path) create

    self pkg do(
      downloader isNil ifTrue(
        setDownloader(Eerie PackageDownloader detect(uri, path)))

      runHook("beforeDownload")
      downloader download
      runHook("afterDownload")
    )

    true)

  execute := method(
    self pkg do(
      installer isNil ifTrue(
        setInstaller(Eerie PackageInstaller detect(path)))
 
      runHook("beforeInstall")
      installer install
      loadInfo      
    )

    self pkg env appendPackage(self pkg)
    self pkg runHook("afterInstall")

    true)
)

