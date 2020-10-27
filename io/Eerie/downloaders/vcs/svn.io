svn := Object clone do(

    cmd := "svn"

    check := method(url,
        if(url containsSeq("git://") or url containsSeq(".git"), return false)
        r := Eerie sh("svn info " .. url, true)
        r exitStatus == 0 and r stderr containsSeq("Not a valid") not)

    download := list("co #{self url} #{self destDir path}")

)
