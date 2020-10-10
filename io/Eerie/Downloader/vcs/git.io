git := Object clone do(
    check     := method(uri,
        uri containsSeq("git://") or uri containsSeq(".git")
    )

    cmd         := "git"
    download    := list("clone #{self uri} #{self path}", "submodule init", "submodule update")
    update      := list("pull", "submodule update")

    # Unfortunately, this isn't working as expected and there seems to be
    # no actual way of checking for updates in a repo without pulling it
    #hasUpdates  := method(path,
    # git ls-remote reference: ftp.sunet.se/pub/Linux/kernel.org/software/scm/git/docs/git-ls-remote.html
    #r := System runCommand("git ls-remote " .. path)
    #refs := r stdout split("\n") map(split("\t") reverse)

    #head := refs detect(first == "HEAD") second
    #remoteHead := refs detect(first == "refs/remotes/origin/HEAD") second

    #Eerie log("Git repo changes (#{path}):", "debug")
    #Eerie log("HEAD: #{head}", "debug")
    #Eerie log("refs/remotes/origin/HEAD: #{remoteHead}", "debug")

    #head != remoteHead)

    hasUpdates := method(true)
)
