p7zip := Object clone do (
    cmd := "7za x #{self url} -o #{self destDir path}"
    extensions := list("7z")
)
