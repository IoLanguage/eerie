InstallAction := Eerie TransactionAction clone do(
   asVerb := "Installing"

   prepare := method(
       if(Eerie packages detect(name asLowercase == self pkg name asLowercase),
           Eerie log("Package with name #{self pkg name} already installed.", "info")
           return false)

       Directory with(self pkg path) create

       self pkg do(
           if(downloader isNil, 
               setDownloader(Eerie PackageDownloader detect(uri, path)))

           runHook("beforeDownload")

           Eerie log("Fetching #{name}", "info")

           if(downloader canDownload(downloader uri) not,
               Eerie FailedDownloadException raise(downloader uri))

           downloader download

           runHook("afterDownload")) true)

    execute := method(
        self pkg do(
            runHook("beforeInstall")
            installer install
            loadInfo)

        Eerie appendPackage(self pkg)
        self pkg runHook("afterInstall")

        true)
)
