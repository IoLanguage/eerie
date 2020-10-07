FileInstaller := Eerie PackageInstaller clone do(
    canInstall := method(path_,
        f := File with(path_)
        f exists and f isRegularFile)

    providesProto := method(
        self providesProto = self root filesWithExtension("io") first baseName \
        makeFirstCharacterUppercase)

    install := method(
        super(install)
        self loadConfig)

    buildPackageJson := method(
        self fileNamed("eerie.json") remove create openForUpdating write(
            Map with(
                "author", User name,
                "dependencies", list(),
                "protos", list(self providesProto)) asJson) close)

    extractDataFromPackageJson := method(
        self fileNamed("depends") remove create openForUpdating write("\n") \
            close
        self fileNamed("protos")  remove create openForUpdating write(
            self providesProto .. "\n") close)
)
