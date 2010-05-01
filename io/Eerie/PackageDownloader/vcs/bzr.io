# WARNING: Not tested
bzr := Object clone do(
  check := method(uri,
    # TODO: Find out if there is a way to determine if
    # there is are some chages on server (without actually pulling the repo)
    true)

  cmd         := "bzr"
  download    := list("branch #{self uri} #{self path}")
  update      := list("update")
  hasUpdates  := method(true)
)
