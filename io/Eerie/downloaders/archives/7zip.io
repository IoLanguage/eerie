p7zip := Object clone do (
    extensions := list("7z")
    cmd := "7za x #{self url} -o #{self path}"
)
