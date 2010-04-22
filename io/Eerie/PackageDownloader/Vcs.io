VcsDownloader := Eerie PackageDownloader clone do(
  vcs := Object clone do(
    doRelativeFile("vcs/git.io")
    doRelativeFile("vcs/svn.io")
    doRelativeFile("vcs/hg.io")
  )

  vcsCmd := method(args,
    dir := nil
    Directory with(self path) exists ifTrue(
      dir = self path)

    Eerie sh((self vcs cmd) .. " " .. args, true, dir))

  runCommands := method(cmds,
    cmds foreach(cmd,
      self vcsCmd(cmd interpolate))

    true)

  whichVcs := method(_uri,
    self vcs slotNames foreach(name,
      self vcs getSlot(name) check(_uri) ifTrue(
        return(name)))

    nil)

  chooseVcs := lazySlot(
    self vcs = self vcs getSlot(self whichVcs(self uri)))

  // Reimplementation of default PackageDownloader methods
  canDownload = method(_uri,
    self whichVcs(_uri) != nil)

  download = method(
    self chooseVcs
    self root files isEmpty ifTrue(
      self root remove)
    self runCommands(self vcs download))

  update = method(
    self chooseVcs
    self runCommands(self vcs update))

  hasUpdates = method(
    self chooseVcs
    self vcs hasUpdates(self path))
)
