# Eerie

The package manager for Io.

Eerie may install packages from a specifically structured directory, a single
file or:

#### Archive

- 7zip
- rar
- tarbz2
- targz
- zip

#### Version Control System

- bazaar
- git
- mercurial
- svn




## Installing

If you installed Io and didn't use `-DWITHOUT_EERIE` flag, Eerie is already
installed in your system. So these instructions are for Eerie developers.

```shell
$ git clone https://github.com/IoLanguage/eerie.git
$ cd eerie
$ io setup.io ~/.path_to_your_shell_startup_script
$ source ~/.path_to_your_shell_startup_script
```

For development purposes you need to install Eerie from a local directory, so
Eerie will remember the path for its sources and you'll be able to update it
easily calling `eerie selfUpdate`. 

Use `-dev` flag for this:

```shell
io setup.io -dev
```




## Usage

To open documentation in your browser:

```shell
eerie doc
```

Besides of the API, which you can use inside of your scripts, Eerie has a
command-line interface. For example, to install
[jasmineio](https://github.com/bekkopen/jasmineio) package run:

```
$ eerie install https://github.com/bekkopen/jasmineio.git
```

Run `eerie -T` to view all the available commands:

```shell
Default:
  Usage: eerie <task>

  activate <name>
    Sets environment as default.

  doc <name>
    Opens documentation for the package in the browser.
    Or opens Eerie documentation, if package name isn't specified.

  envs
    Lists all envs. Active environment has an asterisk before its name.

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
    Uses verbose output - debug messages, shell commands - everything will be prin
ted.
    Watch out for information overload.

Pkg:
  Usage: eerie pkg:<task>

  create <name> <path>
    Creates an empty package structure.
    If <path> is omitted, new directory will be created in current working directo
ry.

  doc <name>
    Opens documentation for the package in the browser.
    Or opens Eerie documentation, if package name isn't specified.

  hook <hookName> <packageName>
    Runs a hook with name at first argument for the package with name at the secon
d one.

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
