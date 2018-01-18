UpdateAction := Eerie TransactionAction clone do(
  name := "Update"
  asVerb := "Updating"

  prepare := method(
    self pkg downloader hasUpdates
  )

  execute := method(
    self pkg do(
      runHook("beforeUpdate")

      downloader canDownload(downloader uri) ifFalse(
          Eerie FailedDownloadException raise(downloader uri)
      )
      downloader update
      installer install
      loadInfo

      runHook("afterUpdate"))

    true
  )
)
