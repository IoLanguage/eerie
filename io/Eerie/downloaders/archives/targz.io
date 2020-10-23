targz := Object clone do (
    extensions := list("tar.gz", "tgz")
    cmd := "tar -xzf #{self url} -C #{self path}"
)
