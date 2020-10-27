Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")
Importer addSearchPath("io/Eerie/downloaders")

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

        # url := "foo/bar/baz"
        # downloader = Downloader detect(url, destDir)
        # assertEquals(downloader type, DirectoryDownloader type)
        # assertEquals(downloader url, url)

        url := "https://github.com/test/test.git"
        downloader = Downloader detect(url, destDir)
        assertEquals(downloader type, VcsDownloader type)
        assertEquals(downloader url, url)

        url := "https://something.com/package.zip"
        downloader = Downloader detect(url, destDir)
        assertEquals(downloader type, ArchiveDownloader type)
        assertEquals(downloader url, url)
        
        url := "https://something.com/package.tar.gz"
        downloader = Downloader detect(url, destDir)
        assertEquals(downloader type, ArchiveDownloader type)
        assertEquals(downloader url, url)

        url := "https://google.com"
        e := try (Downloader detect(url, destDir))
        assertEquals(e error type, Downloader DetectError type))

)
