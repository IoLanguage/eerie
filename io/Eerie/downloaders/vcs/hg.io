hg := Object clone do(
    check := method(url,
        # FIXME this should be replaced with exception handling
        statusCode := Eerie sh("hg identify " .. url)
        if(statusCode == 0, return true, return false)
    )

    cmd         := "hg"
    download    := list("clone #{self url} #{self path}")
    update      := list("update tip")
    hasUpdates  := method(true)
)
