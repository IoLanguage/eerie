Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")
Importer addSearchPath("io/Eerie/downloaders")

DownloaderTest := UnitTest clone do (

    doFile("io/Eerie/downloaders/Directory.io")

    testDetect := method(
        Database dir := Directory with("tests/db")
        db := Database clone
        downloader := Downloader detect(
            "AFakeAddon", 
            Directory with("tests/deleteme"))
        assertEquals(downloader type, DirectoryDownloader type)
        assertEquals(downloader url, db valueFor("AFakeAddon", "url")))

)
