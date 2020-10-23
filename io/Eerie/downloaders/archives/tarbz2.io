tarbz2 := Object clone do (
    extensions := list("tar.bz2")
    cmd := "tar -xjf #{self url} -C #{self path}"
)
