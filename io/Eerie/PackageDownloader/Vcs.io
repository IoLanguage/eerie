VcsDownloader := Eerie PackageDownloader clone do(
  vcs := Object clone do(
    doRelativeFile("vcs/git.io")
    doRelativeFile("vcs/svn.io")
    doRelativeFile("vcs/hg.io")
  )

  vcsCmd := method(args,
    cdCmd := ""
    Directory with(self path) exists ifTrue(
      cdCmd = "cd " .. self path .. " && ")

    Eerie sh(cdCmd .. "#{self vcs cmd} #{args}" interpolate))

  runCommands := method(cmds,
    cmds foreach(cmd,
      self vcsCmd(cmd interpolate))

    true)

  whichVcs := method(_uri,
    self vcs slotNames foreach(name,
      self vcs getSlot(name) check(_uri) ifTrue(
        return(name)))

    nil)

  canDownload := method(_uri,
    self whichVcs(_uri) != nil)

  download := method(
    self vcs := self vcs getSlot(self whichVcs(self uri))
    self root := Directory with(self path)

    # during
    self root files isEmpty ifTrue(
      self root remove)
    self runCommands(self vcs download))

  update := method(
    self vcs := self vcs getSlot(self whichVcs(self uri))
    self runCommands(self vcs update))
)