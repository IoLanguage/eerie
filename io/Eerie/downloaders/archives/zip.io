zip := Object clone do (
    cmd := "unzip #{self url} -d #{self destDir path}"
    extensions := list("zip")
)
