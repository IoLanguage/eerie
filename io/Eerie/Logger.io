//metadoc Logger category API
/*metadoc Logger description 
This proto is responsible for printing output. 

Rainbow is used for styling. To set style use syntax `[[rainbowMethod;`.
For example:

```Io
Logger log("[[red;Hello, [[bold;World")
```

*/

Logger := Object clone do (

    //doc Logger filter Get log filter value (see `Logger setFilter`).
    /*doc Logger setFilter(Sequence)
    Set filter to one of:
    - `"error"` (only errors will be logged)
    - `"warning"` (errors and warnings)
    - `"info"` (error, warnings on some additional info)
    - `"debug"` (errors, warnings, additional info and debug message)
    - `"trace"` (everything)

    The default is `"info"`.

    You can also set this value using `EERIE_LOG_FILTER` environment variable.*/
    filter ::= lazySlot(
        System getEnvironmentVariable("EERIE_LOG_FILTER") ifNilEval("info"))

    _logMods := Map with(
        "info",         " -",
        "error",        " ERROR: ",
        "warning",      " WARNING: ",
        "console",      " >",
        "debug",        " #",
        "install",      " +",
        "transaction",  "->",
        "output",       "")

    /*doc Logger log(message, mode) 
    Displays the message to the user. Mode can be `"info"`, `"error"`,
    `"console"`, `"debug"` or `"output"`.*/
    log := method(str, mode,
        self _checkMode(mode)
        mode ifNil(mode = "info")
        if (self _shouldPrint(mode) not, return)

        stream := if (mode == "error",
            Rainbow isStderr = true
            File standardError,

            File standardOutput)

        self _parseMode(mode, stream)
        self _parse(str asUTF8 interpolate(call sender), stream)
        stream write("\n")

        Rainbow isStderr = false)

    _checkMode := method(mode,
        if (mode isNil, return)
        
        if (self _logMods keys contains(mode) not, 
            Exception raise(UnknownModeError with(mode))))

    # considers `filter` value to return a bool whether logger should print
    # output
    _shouldPrint := method(mode,
        self _filterToModes contains(mode))

    # returns list of modes for current `filter` value
    _filterToModes := method(
        if (self filter == "error") then (
            return list("error")
        ) elseif (self filter == "warning") then (
            return list("error", "warning")
        ) elseif (self filter == "info") then (
            return list("error", "warning", "output", "info", "install")
        ) elseif (self filter == "debug") then (
            return list("error", "warning", "output", "info", "install",
                "debug", "console")
        ) elseif (self filter == "trace") then (
            return self _logMods keys
        ) else (
            Exception raise(UnknownFilterError with(self filter))))

    _parseMode := method(mode, stream,
        if (mode == "error", Rainbow bold redBg)
        if (mode == "warning", Rainbow bold black yellowBg)

        stream write(self _logMods at(mode))

        if (mode == "console") then (
            Rainbow gray
        ) elseif (mode == "debug") then (
            Rainbow brightYellow
        ) else (
            Rainbow reset)

        if (mode != "output", stream write(" ")))

    _parse := method(str, stream,
        str split("[[") foreach(part, self _parsePart(part, stream))
        Rainbow reset)

    _parsePart := method(part, stream,
        split := part splitNoEmpties(";")
        if (split isEmpty) then (
            return
        ) elseif (split size == 1) then (
            stream write(split at(0))
        ) else (
            Rainbow doString(split at(0))
            stream write(split at(1))))

)

Logger clone := Logger

# Logger error types
Logger do (

    //doc Logger UnknownFilterError
    UnknownFilterError := Eerie Error clone setErrorMsg(
        "Unknown logger filter: \"#{call evalArgAt(0)}\"")

    //doc Logger UnknownModeError
    UnknownModeError := Eerie Error clone setErrorMsg(
        "Unknown logger mode: \"#{call evalArgAt(0)}\"")

)
