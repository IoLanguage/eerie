targz := Object clone do(
  extensions  := list("tar.gz", "tgz")
  cmd         := "tar -xzf #{self uri} -C #{self path}"
)
