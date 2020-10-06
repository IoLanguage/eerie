IoAddonInstaller := Eerie PackageInstaller clone do(
    canInstall := method(_path,
        _pathDir := Directory with(_path)
        ioDir := _pathDir directoryNamed("io")

        _pathDir exists and(ioDir exists))

    install := method(
        self loadConfig

        sourceDir := self dirNamed("source") createIfAbsent
        if(sourceDir files isEmpty not, self compile)

        binDir := self dirNamed("bin") createIfAbsent
        if(Eerie isGlobal and(binDir files isEmpty not), self installBinaries)

        true)
)
