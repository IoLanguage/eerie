Importer addSearchPath("io")

System setEnvironmentVariable("EERIEDIR", Directory currentWorkingDirectory)
System setEnvironmentVariable("EERIE_LOG_FILTER", "debug")
Eerie Database dir := Directory with("tests/db")
