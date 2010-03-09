FileDownloader := Eerie PackageDownloader clone do(
  canDownload := method(uri,
    f := File with(uri)
    f exists and(f name containsSeq(".io")))

  download := method(
    self createSkeleton
    File with(self uri) copyTo(self path .. "/io"))

  update := method(
    original  := File with(self uri) lastDataChangeDate
    copy      := Directory with(self path .. "/io/") filesWithExtension("io") first lastDataChangeDate

    (original > copy) ifTrue(
      self download))
)