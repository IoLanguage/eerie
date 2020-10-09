//metadoc Error category API 
//metadoc Error description Error types.

//doc Eerie Error
Eerie Error := Error clone do (
    errorMsg ::= nil

    with := method(msg,
        Eerie Transaction releaseLock
        super(with(self errorMsg interpolate)))
)


Eerie do(
    //doc Eerie AlreadyInstalledError
    AlreadyInstalledError := Error clone setErrorMsg(
        "Package is already installed at #{call evalArgAt(0)}.")
    
    //doc Eerie FailedDownloadError
    FailedDownloadError := Error clone setErrorMsg(
        "Fetching package from #{call evalArgAt(0)} failed.")

    //doc Eerie MissingProtoError
    MissingProtoError := Error clone setErrorMsg(
        "Package '#{call evalArgAt(0)}' required Proto '#{call evalArgAt(1)}" ..
        " which is missing'.")

    //doc Eerie MissingPackageError
    MissingPackageError := Error clone setErrorMsg(
        "Package '#{call evalArgAt(0)}' is missing.")

    //doc Eerie NotPackageError
    NotPackageError := Error clone setErrorMsg(
        "The directory '#{call evalArgAt(0)}' is not recognised as Eerie "..
        "package.")

    //doc Eerie InsufficientManifestError
    InsufficientManifestError := Error clone \
        setErrorMsg("The manifest at '#{call evalArgAt(0)}' doesn't satisfy " ..
            "all requirements." .. 
            "#{if(call evalArgAt(1) isNil, " ..
                "\"\", \"\\n\" .. call evalArgAt(1))}")
)
