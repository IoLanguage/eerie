Install := Eerie Action clone do (

    _alreadyInstalled := method(
        self _parent addonDirFor(self _dependency) exists)

    # Get git branch (`Sequence` or `nil`) for dependency name (`Sequence`).
    # 
    # There are two scenarios for `branch` configuration:
    # 
    # 1. The user can specify branch per dependency in `addons`:
    # ```
    # ...
    # "addons": [
    #   {
    #      ...
    #      "branch": "develop"
    #   }
    # ]
    # ...
    # 
    # ```
    # 
    # 2. The developer can specify main `"branch"` for the package.
    # 
    # The first scenario has more priority, so we try to get the user specified
    # branch first and then if it's `nil` we check the developer's one.
    prepare := method(
        if (self _alreadyInstalled, return)

        url := self _dependency url ifNilEval(
            Eerie database valueFor(self _dependency name, "url"))

        if (url isNil or url isEmpty, 
            Exception raise(NoUrlError with(self _dependency name)))

        downloader := Downloader detect(uri, self _parent tmpDir)
        downloader download

        self package = Package with(downloader destDir)

        self package branch = self _dependency branch ifNilEval(
            self package branch))

    execute := method(
        if (self _alreadyInstalled, return)

        installer := Installer with(
            self package, 
            self _parent addonDirFor(self package name),
            self _parent destBinDir)

        installer install(self _dependency version)

        self _parent tmpDir remove)

)

Install do (

    NoUrlError := Eerie Error clone setErrorMsg(
        "URL for #{call evalArgAt(0)} is not found.")

)
