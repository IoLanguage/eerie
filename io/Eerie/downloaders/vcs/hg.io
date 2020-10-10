hg := Object clone do(
    check := method(uri,
        statusCode := Eerie sh("hg identify " .. uri, false)
        if(statusCode == 0, return true, return false)
    )

    cmd         := "hg"
    download    := list("clone #{self uri} #{self path}")
    update      := list("update tip")
    hasUpdates  := method(true)
)
