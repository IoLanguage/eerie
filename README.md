# Eerie

The package manager for Io.

Eerie can install packages from a specifically structured directory, a single
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




## Installation

There's a big chance you already installed it with Io. Follow the below
instructions only if you're sure you didn't.

### Linux, macOS

```shell
$ git clone https://github.com/IoLanguage/eerie.git
$ cd eerie
$ . ./install_unix.sh
```

The next options are available:

- `--dev` to install Eerie from a local directory, so Eerie will remember the
  path for its sources and you'll be able to update it easily calling `eerie
  selfUpdate`. 
- `--shrc=<path>` path to your shell config (for example
  `--shrc=~/.bash_profile` or `--shrc=~/.zshrc`). Without this flag
  `~/.profile`, `~/.bash_profile` and `~/.zshrc` will be updated automatically
  on unix systems and no files will be updated on Windows.
- `--notouch` with this flag the script will not touch any config file on your
  system. If you use it you should be sure that `EERIEDIR` environment variable
  is set to Eerie directory and is available during sessions, otherwise Eerie
  will not work. It should be also in your `PATH` variable as well as
  `$EERIEDIR/base/bin` and `$EERIEDIR/activeEnv/bin`.


### Tests

To run the tests you should be inside the source root directory. Then:

```shell
$ io tests/run.io
```




## Getting Started

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



## Manifest Format

The manifest file (`eerie.json`) is required for each Eerie package. The table
contains fields and their descriptions.

| Field                              | Type            | Description                                                                  | Presence                             |
| -----                              | ----            | -----------                                                                  | --------                             |
| `name`                             | `string`        | The name of the package.                                                     | **REQUIRED**                         |
| `version`                          | `string`        | The semantic version of the package.                                         | **REQUIRED**                         |
|                                    |                 | The format is `A.B.C-D.E`, where:                                            |                                      |
|                                    |                 | `A` - major version number (required)                                        |                                      |
|                                    |                 | `B` - minor version number (required)                                        |                                      |
|                                    |                 | `C` - patch number (required)                                                |                                      |
|                                    |                 | `D` and `E` are optinal and come after `-` sign.                             |                                      |
|                                    |                 | `D` - case-insensitive pre-release status (`alpha`, `beta`, `rc`)            |                                      |
|                                    |                 | `E` - pre-release version number                                             |                                      |
| `description`                      | `string`        | A short description of the package.                                          | **OPTIONAL**                         |
| `author`                           | `string`        | The author name.                                                             | **REQUIRED**                         |
| `readme`                           | `string`        | Path to the README file.                                                     | **REQUIRED** for published packages  |
| `website`                          | `string`        | Package's website address.                                                   | **OPTIONAL**                         |
| `path`                             | `object`        | The object, which describes from where to install package.                   | **REQUIRED**                         |
| `path.dir`                         | `string`        | Path to local directory.                                                     | **REQUIRED** if none other specified |
| `path.git`                         | `object`        | Git details.                                                                 | **REQUIRED** if none other specified |
| `path.git.url`                     | `string`        | The git link to the package.                                                 | **REQUIRED**                         |
| `path.git.branch`                  | `string`        | Git branch.                                                                  | **OPTIONAL**                         |
| `path.git.tag`                     | `string`        | Git tag.                                                                     | **OPTIONAL**                         |
| `categories`                       | `array<string>` | Categories to which the package applies.                                     | **OPTIONAL**                         |
| `protos`                           | `array<string>` | Protos which the package exposes.                                            | **REQUIRED**                         |
| `dependencies`                     | `object`        | Dependencies of the package.                                                 | **OPTIONAL**                         |
| `dependencies.packages`            | `array<object>` | List of Eerie packages on which the package is dependent.                    | **OPTIONAL**                         |
| `dependencies.packages[n].name`    | `string`        | Name of the package.                                                         | **REQUIRED**                         |
| `dependencies.packages[n].version` | `string`        | The version of the package. Can be shortened.                                | **REQUIRED**                         |
|                                    |                 | The value `"0.1"`, for example, includes all `"0.1"` patches until `"0.2.0"` |                                      |
| `dependencies.packages[n].path`    | `object`        | See `path`.                                                                  | **REQUIRED**                         |
| `dependencies.protos`              | `array<string>` | Protos on which the package is depending.                                    | **OPTIONAL**                         |




## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).


