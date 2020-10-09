InstallAction := Eerie TransactionAction clone do(
   asVerb := "Installing"

   prepare := method(
       if(Eerie installedPackages detect(name asLowercase == self pkg name asLowercase),
           Eerie log("Package with name #{self pkg name} already installed.", "info")
           return false)

       Directory with(self pkg path) create

       self pkg do(
           if(downloader isNil, 
               setDownloader(Eerie PackageDownloader detect(uri, path)))

           runHook("beforeDownload")

           Eerie log("Fetching #{name}", "info")

           if(downloader canDownload(downloader uri) not,
               Exception raise(Eerie FailedDownloadError with(downloader uri)))

           downloader download

           runHook("afterDownload")) true)

    execute := method(
        self pkg runHook("beforeInstall")
        installer := PackageInstaller clone \
            setDestination(Eerie addonsDir) \
                setDestBinName(Eerie globalBinDirName)

        installer install(self pkg, Eerie isGlobal)
        # self pkg loadInfo

        Eerie appendPackage(self pkg)
        self pkg runHook("afterInstall")

        true)
)
