ArchiveDownloader := Eerie PackageDownloader clone do(
  formats := Object clone do(
    doRelativeFile("archives/targz.io")
    doRelativeFile("archives/tarbz2.io")
    doRelativeFile("archives/7zip.io")
    doRelativeFile("archives/zip.io")
    doRelativeFile("archives/rar.io")
  )

  whichFormat := method(uri_,
    self formats slotNames foreach(name,
      self formats getSlot(name) extensions foreach(ext,
        uri_ containsSeq("." .. ext) ifTrue(
          return(name))))

    nil)

  canDownload := method(uri_,
    self whichFormat(uri_) != nil)

  download := method(
    self format := self formats getSlot(self whichFormat(self uri))

    self uri containsSeq("http") ifTrue(
      tmpFile := Directory with(Eerie tmpDir) fileNamed(self uri split("/") last)
      Eerie log("Downloading #{self uri}")
      URL with(self uri) fetchToFile(tmpFile)
      tmpFile exists ifFalse(
        Exception raise("Could not download file #{self uri}." interpolate))
      self uri = tmpFile path)

    Eerie sh(self format cmd interpolate)
    (self root directories size == 1 and self root files isEmpty) ifTrue(
      extraDir = self root directories first name
      Eerie sh("mv #{extraDir} __contents__")
      Eerie sh("mv __contents__/* #{self path}")
      Eerie sh("rm __contents__"))

    tmpFile isNil ifFalse(
      tmpFile remove))

  update := method(
    false)
)