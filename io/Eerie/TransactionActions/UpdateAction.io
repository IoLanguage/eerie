UpdateAction := Eerie TransactionAction clone do(
    name := "Update"
    asVerb := "Updating"

    prepare := method(self pkg downloader hasUpdates)

    execute := method(
        self pkg runHook("beforeUpdate")

        self pkg downloader canDownload(downloader uri) ifFalse(
            Exception raise(Eerie FailedDownloadError with(downloader uri)))

        self pkg downloader update
        installer := PackageInstaller clone \
            setDestination(Eerie addonsDir) \
                setDestBinName(Eerie globalBinDirName)

        installer install(self, Eerie isGlobal)
        # self pkg loadInfo

        self pkg runHook("afterUpdate")

        true)
)
