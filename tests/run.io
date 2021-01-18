System setEnvironmentVariable("EERIEDIR", Directory currentWorkingDirectory)
System setEnvironmentVariable("EERIE_LOG_FILTER", "debug")

Importer addSearchPath("io")

Importer FileImporter importPath("io/Extensions.io")

Loader unload

System exit(if (Eerie TestsRunner clone run(System args at(1)), 0, 1))
