//metadoc Error category API 
//metadoc Error description Error types.

//doc Eerie Exception Exception handling object. 
Eerie Exception := Exception clone do(
    errorMsg ::= nil

    raise := method(arg,
        Eerie Transaction releaseLock
        super(raise(self errorMsg interpolate)))
)

//doc Eerie Error
Eerie Error := Error clone do (
    errorMsg ::= nil

    with := method(arg,
        Eerie Transaction releaseLock
        super(with(self errorMsg interpolate)))
)


Eerie do(
    //doc Eerie AlreadyInstalledException
    AlreadyInstalledException := Exception clone setErrorMsg(
        "Package is already installed at #{arg}.")

    //doc Eerie AlreadyInstalledError
    AlreadyInstalledError := Error clone setErrorMsg(
        "Package is already installed at #{arg}.")
    
    //doc Eerie FailedDownloadException
    FailedDownloadException := Exception clone setErrorMsg(
        "Fetching package from #{arg} failed.")

    //doc Eerie FailedDownloadError
    FailedDownloadError := Error clone setErrorMsg(
        "Fetching package from #{arg} failed.")

    //doc Eerie MissingProtoException
    MissingProtoException := Exception clone setErrorMsg(
        "Package '#{arg at(0)}' required Proto '#{arg at(1)} which" ..
        " is missing'.")

    //doc Eerie MissingProtoError
    MissingProtoError := Error clone setErrorMsg(
        "Package '#{arg at(0)}' required Proto '#{arg at(1)} which" ..
        " is missing'.")

    //doc Eerie MissingPackageException
    MissingPackageException := Exception clone setErrorMsg(
        "Package '#{arg}' is missing.")

    //doc Eerie MissingPackageError
    MissingPackageError := Error clone setErrorMsg(
        "Package '#{arg}' is missing.")

    //doc Eerie MissingTransactionActionException
    MissingTransactionActionException := Exception clone setErrorMsg(
        "There is no '#{arg}' transaction.")

    //doc Eerie MissingTransactionActionError
    MissingTransactionActionError := Error clone setErrorMsg(
        "There is no '#{arg}' transaction.")

    //doc Eerie NotPackageException
    NotPackageException := Exception clone setErrorMsg(
        "The directory '#{arg}' is not recognised as Eerie package.")

    //doc Eerie NotPackageError
    NotPackageError := Error clone setErrorMsg(
        "The directory '#{arg}' is not recognised as Eerie package.")

    //doc Eerie InsufficientManifestException
    InsufficientManifestException := Exception clone \
        setErrorMsg("The manifest at '#{arg at(0)}' doesn't satisfy all " ..
            "requirements.#{if(arg at(1) isNil, \"\", \"\\n\" .. arg at(1))}")

    //doc Eerie InsufficientManifestError
    InsufficientManifestError := Error clone \
        setErrorMsg("The manifest at '#{arg at(0)}' doesn't satisfy all " ..
            "requirements.#{if(arg at(1) isNil, \"\", \"\\n\" .. arg at(1))}")
)
