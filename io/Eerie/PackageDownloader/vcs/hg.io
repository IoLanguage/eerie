hg := Object clone do(
  check := method(uri,
    Eerie sh("hg identify " .. uri, false))

  cmd       := "hg"
  download  := list("clone #{self uri} #{self path}")
  update    := list("update tip")
)
