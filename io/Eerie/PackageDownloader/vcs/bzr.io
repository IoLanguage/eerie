# WARNING: Not tested
bzr := Object clone do(
  check := method(uri,
    Eerie sh("hg identify " .. uri, false))

  cmd       := "bzr"
  download  := list("branch #{self uri} #{self path}")
  update    := list("update")
)
