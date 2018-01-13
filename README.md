# Eerie, package manager for Io

Eerie is an attempt to create feature-full package manager for Io, due to lack of working and usable package managers.
Eerie is modelled after [Rip](https://github.com/defunkt/rip) which means that there is no central repository of packages, and that environments are used as a tool for switching between different versions.

## How to install

```shell
$ git clone --recursive https://github.com/AlesTsurko/eerie.git
$ cd eerie
$ io setup.io ~/.path_to_your_shell_startup_script
$ source ~/.path_to_your_shell_startup_script
```

## Usage

Eerie currently ships with a simple `eerie` command which can do all sorts exciting of things!

```
$ eerie install git://github.com/josip/generys.git
```

That will, for example, install the Generys package! How exciting!

Here is a full list of available commands (run `eerie -T` to view it):

```shell
Default:
  Usage: eerie <task>

  activate <name>
    Sets environment as default.

  envs
    Lists all envs. Active environment has an asterisk before its name.

  install <uri>
    Installs new plugin.

  pkgs
    Lists all installed plugins.

  releaseLock
    Removes transaction lock.
    Use only if you are sure that process which placed the lock isn't running.

  remove <name>
    Removes a plugin.

  selfUpdate
    Updates Eerie and its dependencies.

  update <name>
    Updates the package and all of its dependencies.

Env:
  Usage: eerie env:<task>

  activate <name>
    Sets environment as default.

  active
    Prints the name of active env.

  create <name>
    Creates a new environment.

  list
    Lists all envs. Active environment has an asterisk before its name.

  remove <name>
    Removes an env with all its packages.

Options:
  Usage: eerie -<task>

  help
    Quick usage notes.

  ns
    Lists all namespaces.

  s
    Print nothing to stdout.

  v
    Uses verbose output - debug messages, shell commands - everything will be printed.
    Watch out for information overload.

Pkg:
  Usage: eerie pkg:<task>

  create <name> <path>
    Creates an empty package structure.
    If <path> is omitted, new directory will be created in current working directory.

  info <name>
    Shows description of a package.

  install <uri>
    Installs new plugin.

  list
    Lists all installed plugins.

  remove <name>
    Removes a plugin.

  update <name>
    Updates the package and all of its dependencies.

  updateAll
    Updates all packages within current env.

Plugin:
  Usage: eerie plugin:<task>
```

For a complete guide on installing and using Eerie check out its [web site](http://josip.github.com/eerie).

## Features

  * Working package manager
  * Converting local files and folders into packages
  * Installing from Git, SVN, Bazaar and Mercurial repositories, as well as tarballs (.tar.bz2, .tar.gz, .7z, , .zip, .rar)
  * Addons with .c files are being compiled and loaded properly
  * All installations are local to the current user, there is no "global mode"
  * Command-line tool
