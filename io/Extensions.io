Error do (

    //doc Error setErrorMsg(Sequence)
    /*doc Error errorMsg 
    Error message template which is supposed to be used in pair with 
    `Error withArgs`.*/
    errorMsg ::= nil

    /*doc Error withArgs 
    An error with variable arguments. 

    This method is supposed to be used in pair with `Error setErrorMsg`.

    Example:

    ```Io
    # first you define your error type
    SystemCommandError := Error clone setErrorMsg(
        "Command '#{call evalArgAt(0)}' exited with status code " .. 
        "#{call evalArgAt(1)}:\n#{call evalArgAt(2)}")

    # then you can raise it with arguments
    Exception raise(SystemCommandError withArgs("foo", 1, "bar"))
    ```
    */
    withArgs := method(self with(self errorMsg interpolate))

)

System do (

    /*doc System sh(cmd[, silent=false, path=cwd])
    Executes system command. Raises exception with `System SystemCommandError`
    on failure. Will not print any output if `silent` is `true`.

    Returns the object returned by `System runCommand`.

    **WARNING**: this method removes all files with "-stdout" and "-stderr"
    suffixes inside the directory in which the command is supposed to be run.*/
    sh := method(cmd, silent, path,
        cmd = cmd interpolate(call sender)
        if (silent not, Logger log(cmd, "console"))
        
        prevDir := nil
        if(path != nil and path != ".",
            prevDir = Directory currentWorkingDirectory
            Directory setCurrentWorkingDirectory(path))

        cmdOut := System runCommand(cmd)
        stdOut := cmdOut stdout
        stdErr := cmdOut stderr

        System _cleanRunCommand

        prevDir isNil ifFalse(Directory setCurrentWorkingDirectory(prevDir))
        
        if(cmdOut exitStatus != 0,
            Exception raise(
                SystemCommandError withArgs(cmd, cmdOut exitStatus, stdErr)))

        cmdOut)

    # remove *-stdout and *-stderr files, which are kept in result of
    # System runCommand call
    _cleanRunCommand := method(
        Directory clone files select(file, 
            file name endsWithSeq("-stdout") or \
                file name endsWithSeq("-stderr")) \
                    foreach(remove))

)

System do (

    //doc System SystemCommandError
    SystemCommandError := Error clone setErrorMsg(
        "Command '#{call evalArgAt(0)}' exited with status code " .. 
        "#{call evalArgAt(1)}:\n#{call evalArgAt(2)}")

)

/*doc Directory copyTo 
Copy content of a directory into destination directory path.*/
Directory copyTo := method(destination,
    destination createIfAbsent
    absoluteDest := Path absolute(destination path)

    # keep path to the current directory to return when we're done
    wd := Directory currentWorkingDirectory
    # change directory, to copy only what's inside the source
    Directory setCurrentWorkingDirectory(self path)


    Directory clone walk(item,
        newPath := absoluteDest .. "/" .. item path
        if (item type == File type) then (
            Directory with(newPath pathComponent) createIfAbsent 
            # `File copyToPath` has rights issues, `File setPath` too, so we
            # just create a new file here and copy the content of the source
            # into it
            File with(newPath) create setContents(item contents) close
        ) else (
            Directory createIfAbsent(newPath)))

    Directory setCurrentWorkingDirectory(wd))
