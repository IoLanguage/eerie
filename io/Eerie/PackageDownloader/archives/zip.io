zip := Object clone do(
  extensions  := list("zip")
  cmd         := "unzip #{self uri} -d #{self path}"
)
