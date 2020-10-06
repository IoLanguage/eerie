InstallAction := Eerie TransactionAction clone do(
  asVerb := "Installing"

  prepare := method(
      if(Eerie packages detect(name asLowercase == self pkg name asLowercase),
          Eerie log("Package with name #{self pkg name} already installed in #{Eerie usedEnv name}." interpolate, "info")
          return(false)
      )

      Directory with(self pkg path) create

      self pkg do(
          downloader isNil ifTrue(
              setDownloader(Eerie PackageDownloader detect(uri, path))
          )

          runHook("beforeDownload")
          Eerie log("Fetching #{name}", "info")
          downloader canDownload(downloader uri) ifFalse(
              Eerie FailedDownloadException raise(downloader uri)
          )
          downloader download
          runHook("afterDownload")
      )

      true
  )

  execute := method(
    self pkg do(
      installer isNil ifTrue(
        setInstaller(Eerie PackageInstaller detect(path)))
 
      runHook("beforeInstall")
      installer install
      loadInfo      
    )

    Eerie appendPackage(self pkg)
    self pkg runHook("afterInstall")

    true)
)

