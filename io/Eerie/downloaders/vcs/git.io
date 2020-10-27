git := Object clone do(

    cmd := "git"

    check := method(url, url containsSeq("git://") or url containsSeq(".git"))

    download := list(
        "clone #{self url} #{self destDir path}",
        "submodule init",
        "submodule update")
    
)
