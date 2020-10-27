tarbz2 := Object clone do (
    cmd := "tar -xjf #{self url} -C #{self destDir path}"
    extensions := list("tar.bz2")
)
