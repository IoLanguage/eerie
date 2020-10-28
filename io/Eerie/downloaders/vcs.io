VcsDownloader := Eerie Downloader clone do (

    _vcs := Object clone do (
        doRelativeFile("vcs/git.io")
        # we don't use svn yet
        # doRelativeFile("vcs/svn.io")
    )

    canDownload = method(url, self _whichVcs(url) != nil)

    download = method(
        if (self destDir files isEmpty, self destDir remove)
        self _runCommands(self _chosenVcs download))

    _chosenVcs := lazySlot(self _vcs getSlot(self _whichVcs(self url)))

    _whichVcs := method(url,
        self _vcs slotNames detect(name, self _vcs getSlot(name) check(url)))

    _runCommands := method(cmds,
        cmds foreach(cmd, self _vcsCmd(cmd interpolate)))

    _vcsCmd := method(args,
        e := try (
            Eerie sh(
                self _chosenVcs cmd .. " " .. args,
                false, 
                self destDir path))

        e catch (
            Exception raise(
                Downloader DownloadError with(self url, e error message))))

)
