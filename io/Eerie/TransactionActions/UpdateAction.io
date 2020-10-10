UpdateAction := Eerie TransactionAction clone do(
    name := "Update"
    asVerb := "Updating"

    prepare := method(self pkg downloader hasUpdates)

    execute := method(
        self pkg runHook("beforeUpdate")

        self pkg downloader canDownload(downloader uri) ifFalse(
            Exception raise(
                PackageDownloader FailedDownloadError with(downloader uri)))

        self pkg downloader update
        installer := PackageInstaller with(self pkg) \
            setDestination(Eerie addonsDir) \
                setDestBinName(Eerie globalBinDirName)

        installer install(Eerie isGlobal)
        # self pkg loadInfo

        self pkg runHook("afterUpdate")

        true)
)
