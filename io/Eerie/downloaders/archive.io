# We support only git and directory downloaders yet, but archive can be added in
# the future.
#
# For this we need a library for doing HTTP and HTTPS requests. We should add a
# downloader, which will download the file via URL and then locally detect which
# downloader we should use next.

ArchiveDownloader := Eerie Downloader clone do (

    formats := Object clone do (
        doRelativeFile("archives/targz.io")
        doRelativeFile("archives/tarbz2.io")
        doRelativeFile("archives/7zip.io")
        doRelativeFile("archives/zip.io")
        doRelativeFile("archives/rar.io")
    )

    whichFormat := method(uri_,
        self formats slotNames foreach(name,
            self formats getSlot(name) extensions foreach(ext,
                if (uri_ containsSeq("." .. ext), return name)))

        nil)

    canDownload = method(uri_, self whichFormat(uri_) != nil)

    download = method(
        self format := self formats getSlot(self whichFormat(self url))
        tmpFile := nil

        # FIXME `Socket` (`URL`) doesn't work with https, so http only
        if (self url containsSeq("http"),
            # TODO we should create a Url downloader, for which we download
            # first and then we locally determine what kind of downloader we
            # should use next
            tmpFile = Package global tmpDir fileNamed(self url split("/") last)
            URL with(self url) fetchToFile(tmpFile)

            if (tmpFile exists not,
                Exception raise(
                    Downloader DownloadError with(
                        self url,
                        "Error fetching to temporary file.")))

            self url = tmpFile path)

        e := try (System sh(self format cmd interpolate))

        e catch (
            Exception raise(
                Downloader DownloadError with(self url, e error message)))

        # If archive contains a directory with all the code we need to move
        # everything out of there
        if (self destDir directories size == 1 and self destDir files isEmpty,
            extraDir := self destDir directories first name
            Directory with(
                self destDir path .. "/" .. extraDir) moveTo(self destDir path))

        tmpFile ?remove)

)
