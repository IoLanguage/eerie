Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

DownloaderTest := UnitTest clone do (

    doFile("io/Eerie/downloaders/Directory.io")
    doFile("io/Eerie/downloaders/Vcs.io")
    doFile("io/Eerie/downloaders/Archive.io")

    testDetect := method(
        Database dir := Directory with("tests/db")
        destDir := Directory with("tests/rm_me_downloader_dest")

        db := Database clone
        pkgName := "AFakeAddon"
        downloader := Downloader detect(pkgName, destDir)
        assertEquals(downloader type, DirectoryDownloader type)
        assertEquals(downloader url, db valueFor(pkgName, "url"))

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
        e := try (Downloader detect(url, destDir))
        assertEquals(e error type, Downloader DetectError type))

    _expectDownloaderTypeFor := method(url, expected,
        destDir := Directory with("tests/rm_me_downloader_dest")
        downloader := Downloader detect(url, destDir)
        assertEquals(downloader type, expected)
        assertEquals(downloader url, url))

)
