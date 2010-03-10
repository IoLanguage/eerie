VcsDownloader := Eerie PackageDownloader clone do(
  vcs := Object clone do(
    git := Object clone do(
      check     := method(uri,
        uri containsSeq("git://") or uri containsSeq(".git"))

      cmd       := "git"
      download  := list("clone #{self uri} #{self path}", "submodule init", "submodule update")
      update    := list("update", "submodule update")
    )

    svn := Object clone do(
      check := method(uri,
        Eerie sh("svn info " .. uri, false))

      cmd       := "svn"
      download  := list("co #{self uri} #{self path}")
      update    := list("up")
    )
  )
  
  vcsCmd := method(args,
    Eerie sh((self vcs cmd) .. " " .. args))
  
  runCommands := method(cmds,
    cmds foreach(cmd,
      self vcsCmd(cmd interpolate)))

  whichVcs := method(_uri,
    self vcs slotNames foreach(name,
      self vcs getSlot(name) check(_uri) ifTrue(
        return(name)))

    nil)

  canDownload := method(_uri,
    self whichVcs(_uri) != nil)
    
  download := method(
    self vcs := self vcs getSlot(self whichVcs(self uri))

    Directory with(self path) remove
    self runCommands(self vcs download))
  
  update := method(
    self vcs := self vcs getSlot(self whichVcs(self uri))
    self runCommands(self vcs update))
)