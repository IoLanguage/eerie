zip := Object clone do (
    extensions := list("zip")
    cmd := "unzip #{self url} -d #{self destDir path}"
)
