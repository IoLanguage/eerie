//metadoc Exception category Utilites 
/*metadoc Exception description
To check what type of error has been raise you can use:
<pre><code class="language-io">install := try(Eerie Transaction do(
  begin
  install(Eerie Env packageNamed("fakePackage"))
  run
))
install catch(
  # install problem == "missingPackage"
  if(install isMissingPackage, "You fool! You can't install a fake package!" println))
</code></pre>
*/

/* Exception do( */
    /* raise := method(arg, */
        /* Eerie transaction releaseLock */
        /* Eerie revertConfig */
        /* super(raise(arg)) */
    /* ) */
/* ) */

//doc Eerie Exception Exception handling object. 
Eerie Exception := Exception clone do(
  errorMsg ::= nil

  raise := method(arg,
    Eerie Transaction releaseLock
    super(raise(self errorMsg interpolate)))
)


Eerie do(
  //doc Eerie AlreadyInstalledException
  AlreadyInstalledException := Exception clone setErrorMsg("Package is already installed at #{arg}.")
  //doc Eerie ExistingEnvException
  ExistingEnvException      := Exception clone setErrorMsg("Environment with the same name already exists.")
  //doc Eerie FailedDownloadException
  FailedDownloadException   := Exception clone setErrorMsg("Fetching package from #{arg} failed.")
  //doc Eerie MissingProtoException
  MissingProtoException     := Exception clone setErrorMsg("Package '#{arg at(0)}' required Proto '#{arg at(1)} which is missing'.")
  //doc Eerie MissingPackageException
  MissingPackageException   := Exception clone setErrorMsg("Package '#{arg}' is missing.")
  //doc Eerie MissingTransactionActionException
  MissingTransactionActionException  := Exception clone setErrorMsg("There is no '#{arg}' transaction.")
)
