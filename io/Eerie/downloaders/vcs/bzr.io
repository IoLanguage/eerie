# WARNING: Not tested
bzr := Object clone do(
  check := method(url,
    # TODO: More intelligent check
    url containsSeq("bzr://"))

  cmd         := "bzr"
  download    := list("checkout --lightweight #{self url} #{self path}")
  update      := list("update")
  hasUpdates  := method(
    # TODO: Find out if there is a way to determine if
    # there is are some chages on server (without actually pulling the repo),
    true)
)
