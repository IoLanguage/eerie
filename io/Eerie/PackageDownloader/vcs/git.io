git := Object clone do(
  check     := method(uri,
    uri containsSeq("git://") or uri containsSeq(".git"))

  cmd       := "git"
  download  := list("clone #{self uri} #{self path}", "submodule init", "submodule update")
  update    := list("pull", "submodule update")
)
