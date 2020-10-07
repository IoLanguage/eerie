DirectoryInstaller := Eerie PackageInstaller clone do(
    canInstall := method(_path,
        dir := Directory with(_path)
        packageJson := File with(_path .. "/eerie.json")
        dir exists and(dir filesWithExtension("io") isEmpty not) and(
            packageJson exists not))

    protosList := method(
        self protosList = list()
        self root filesWithExtension("io") map(ioFile,
            ioFile baseName at(0) isUppercase ifTrue(
                self protoList append(ioFile baseName)))

        self protosList)

    install := method(
        super(install)
        self loadConfig
        ioDir := self dirNamed("io") create
        ioFiles := Directory with(self path) filesWithExtension("io")
        ioFiles foreach(moveTo(ioDir path))
        return true)

    buildPackageJson := method(
        pkgInfo := self fileNamed("eerie.json")
        if(pkgInfo exists not,
            pkgInfo create openForUpdating write(Map with(
                "author", User name,
                "dependencies", list(),
                "protos", self protosList) asJson) close))

    extractDataFromPackageJson := method(
        deps := self fileNamed("depends")
        if(deps exists not, deps create openForUpdating write("\n") close)

        pprotos := self fileNamed("protos")
        pprotos exists ifFalse(deps create openForUpdating write(
            self protosList join(" ") .. "\n") close))
)
