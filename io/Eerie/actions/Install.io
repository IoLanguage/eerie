Install := Eerie Action clone do(
   asVerb := "Installing"

   prepare := method(
       if(Eerie installedPackages detect(name asLowercase == self pkg name asLowercase),
           Logger log("Package with name #{self pkg name} already installed.", "info")
           return false)

       Directory with(self pkg path) create

       self pkg do(
           if(downloader isNil, 
               setDownloader(Eerie Downloader detect(uri, path)))

           runHook("beforeDownload")

           Logger log("Fetching #{name}", "info")

           if(downloader canDownload(downloader uri) not,
               Exception raise(
                   Downloader FailedDownloadError with(downloader uri)))

           downloader download

           runHook("afterDownload")) true)

    execute := method(
        self pkg runHook("beforeInstall")
        installer := Installer with(self pkg) \
            setRoot(Eerie addonsDir) \
                setDestBinName(Eerie globalBinDirName)

        installer install(Eerie isGlobal)
        # self pkg loadInfo

        Eerie appendPackage(self pkg)
        self pkg runHook("afterInstall")

        true)
)
