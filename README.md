# Eerie

## Installing
Io ships with Eerie by default. But if you need:

```shell
$ git clone https://github.com/IoLanguage/eerie.git
$ cd eerie
$ io setup.io ~/.path_to_your_shell_startup_script
$ source ~/.path_to_your_shell_startup_script
```
For development purposes you'd like to install Eerie from a local directory. You can use `-dev` flag for this:

```shell
io setup.io -dev
```

## Usage

Besides of the API, Eerie has a commandline interface. For example to install [jasmineio](https://github.com/bekkopen/jasmineio) package run:

```
$ eerie install https://github.com/bekkopen/jasmineio.git
```

The list of available commands (run `eerie -T` to view it):

```shell
Default:
  Usage: eerie <task>

  activate <name>
    Sets environment as default.

  envs
    Lists all envs. Active environment has an asterisk before its name.

  help <name>
    Opens documentation for the package in the browser.

  install <uri>
    Installs a new package.

  pkgs
    Lists all packages installed within current env.

  releaseLock
    Removes transaction lock.
    Use only if you are sure that process which placed the lock isn't running.

  remove <name>
    Removes the package.

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
    Prints Eerie version.

  verbose
    Uses verbose output - debug messages, shell commands - everything will be printed.
    Watch out for information overload.

Pkg:
  Usage: eerie pkg:<task>

  create <name> <path>
    Creates an empty package structure.
    If <path> is omitted, new directory will be created in current working directory.

  help <name>
    Opens documentation for the package in the browser.

  hook <hookName> <packageName>
    Runs a hook with name at first argument for the package with name at the second one.

  info <name>
    Shows description of a package.

  install <uri>
    Installs a new package.

  list
    Lists all packages installed within current env.

  remove <name>
    Removes the package.

  update <name>
    Updates the package and all of its dependencies.

  updateAll
    Updates all packages within current env.

Plugin:
  Usage: eerie plugin:<task>

  install <uri>
    Installs a new plugin.

  list
    Lists all installed plugins.

  remove <name>
    Removes a plugin.

  update <name>
    Updates the plugin.
```
