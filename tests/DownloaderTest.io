DownloaderTest := UnitTest clone do (

    doFile("io/Eerie/downloaders/directory.io")
    doFile("io/Eerie/downloaders/vcs.io")
    doFile("io/Eerie/downloaders/archive.io")

    testDetect := method(
        self _expectDownloaderTypeFor("tests/db", DirectoryDownloader type)

        self _expectDownloaderTypeFor(
            "https://github.com/test/test.git",
            VcsDownloader type)

        self _expectDownloaderTypeFor(
            "https://something.com/package.zip",
            ArchiveDownloader type)
        
        self _expectDownloaderTypeFor(
            "foo/bar/package.zip",
            ArchiveDownloader type)

        self _expectDownloaderTypeFor(
            "https://something.com/package.tar.gz",
            ArchiveDownloader type)

        self _expectDownloaderTypeFor(
            "foo/bar/package.tar.gz",
            ArchiveDownloader type)

        url := "https://google.com"
        e := try (Downloader detect(url, Directory with("tests/_tmp")))
        assertEquals(e error type, Downloader DetectError type))

    _expectDownloaderTypeFor := method(url, expected,
        destRoot := Directory with("tests/rm_me_downloader_dest")
        destRoot create remove
        downloader := Downloader detect(url, destRoot)
        assertEquals(downloader type, expected)
        assertEquals(downloader url, url)
        destRoot remove)

)
