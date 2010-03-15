svn := Object clone do(
  check := method(uri,
    r := System runCommand("svn info " .. uri)
    r exitStatus == 0 and r stderr containsSeq("Not a valid") not)

  cmd       := "svn"
  download  := list("co #{self uri} #{self path}")
  update    := list("up")
)
