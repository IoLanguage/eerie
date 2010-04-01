rar := Object clone do(
  extensions  := list("rar")
  cmd         := "unrar x #{self uri}"
)
