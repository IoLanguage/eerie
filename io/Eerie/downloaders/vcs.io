VcsDownloader := Eerie Downloader clone do(

    chosenVcs ::= nil

    vcs := Object clone do (
        doRelativeFile("vcs/git.io")
        doRelativeFile("vcs/svn.io")
    )

    whichVcs := method(_uri,
        self vcs slotNames foreach(name,
            self vcs getSlot(name) check(_uri) ifTrue(
                return name
                break))
        nil)

    canDownload = method(_uri, self whichVcs(_uri) != nil)

    download = method(
        self _chooseVcs
        if (self destDir files isEmpty, 
            self destDir remove)
        self _runCommands(self chosenVcs download))

    _chooseVcs := lazySlot(
        self setChosenVcs(self vcs getSlot(self whichVcs(self url))))

    _runCommands := method(cmds,
        cmds foreach(cmd, self _vcsCmd(cmd interpolate)))

    _vcsCmd := method(args,
        dir := nil

        if (Directory with(self destDir path) exists, 
            dir = self destDir path)

        e := try (
            Eerie sh(self chosenVcs cmd .. " " .. args, false, dir))

        e catch (
            Exception raise(
                Downloader DownloadError with(self url, e error message))))

)
