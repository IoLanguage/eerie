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
        self _parseMode(mode)
        self _parse(str interpolate(call sender))
        write("\n"))

    _parseMode := method(mode,
        if (mode == "error", Rainbow bold redBg)
        write(self _logMods at(mode))

        if (mode == "console") then (
            Rainbow gray
        ) elseif (mode == "debug") then (
            Rainbow brightYellow
        ) else (
            Rainbow reset)

        if (mode != "output", write(" ")))

    _parse := method(str,
        str split("[[") foreach(part, self _parsePart(part))
        Rainbow reset)

    _parsePart := method(part,
        split := part splitNoEmpties(";")
        if (split isEmpty) then (
            return
        ) elseif (split size == 1) then (
            write(split at(0))
        ) else (
            Rainbow doString(split at(0))
            write(split at(1))))

)

Logger clone := Logger
