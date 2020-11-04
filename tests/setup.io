Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

System setEnvironmentVariable("EERIEDIR", Directory currentWorkingDirectory)
System setEnvironmentVariable("EERIE_LOG_FILTER", "info")
Database dir := Directory with("tests/db")
