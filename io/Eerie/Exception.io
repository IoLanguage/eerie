//metadoc Eerie Exception Exception handling object 
/*metadoc Eerie Exception description
To check what type of error has been raise you can use:
<pre><code>install := try(Eerie Transaction do(
  begin
  install(Eerie Env packageNamed("fakePackage"))
  run
))
install catch(
  # install problem == "missingPackage"
  if(install isMissingPackage, "You fool! You can't install a fake package!" println))
</code></pre>
*/
Eerie Exception := Exception clone do(
  //doc Exception problem A short string describing the exception.
  problem ::= nil
  //doc Exception problemMsg Detailed description of exception.
  problemMsg ::= nil

  //doc Exception raise(problem, description) Returns a new Eerie Exception.
  raise := method(problemKey, msg,
    Eerie Transaction releaseLock
    
    self setProblem(problemKey) setMsg(msg)
    self super(raise("Eerie: " .. self problem .. ": " .. self problemMsg)))

  forward := method(
    msgName := call message name
    if(msgName exSlice(0, 2) == "is",
      self problem == call msgName exSlice(2) makeFirstCharacterLowercase))
)
