System setEnvironmentVariable("EERIEDIR", Directory currentWorkingDirectory)
System setEnvironmentVariable("EERIE_LOG_FILTER", "debug")

Importer addSearchPath("io")

System exit(if (Eerie TestsRunner clone run(System args at(1)), 0, 1))
