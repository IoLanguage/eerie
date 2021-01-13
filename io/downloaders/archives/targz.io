targz := Object clone do (
    cmd := "tar -xzf #{self url} -C #{self destDir path}"
    extensions := list("tar.gz", "tgz")
)
