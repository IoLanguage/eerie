Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

System setEnvironmentVariable("EERIEDIR", Directory currentWorkingDirectory)
System setEnvironmentVariable("EERIE_LOG_FILTER", "debug")
Eerie Database dir := Directory with("tests/db")
Database dir := Eerie Database dir
