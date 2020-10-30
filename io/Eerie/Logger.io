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

    _logMods := Map with(
        "info",         " -",
        "error",        " ERROR: ",
        "console",      " >",
        "debug",        " #",
        "install",      " +",
        "transaction",  "->",
        "output",       "")

    /*doc Logger log(message, mode) 
    Displays the message to the user. Mode can be `"info"`, `"error"`,
    `"console"`, `"debug"` or `"output"`.*/
    log := method(str, mode,
        mode ifNil(mode = "info")
        stream := if (mode == "error",
            Rainbow isStderr = true
            File standardError,

            File standardOutput)
        self _parseMode(mode, stream)
        self _parse(str asUTF8 interpolate(call sender), stream)
        stream write("\n")
        Rainbow isStderr = false)

    _parseMode := method(mode, stream,
        if (mode == "error", Rainbow bold redBg)

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
