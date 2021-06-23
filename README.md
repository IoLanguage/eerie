# Eerie

Eerie is a package manager for Io. That means it's a program and a package
itself, which helps you to distribute your projects easier. It manages a
project's dependencies: installs them, updates them, helps you reviewing
dependencies etc.

It can handle packages hosted locally (i.e. a directory) and on the server. When
it's on the server, it can be a git repository or a downloadable archive.

- [Installing](#installing)
    - [Installing Manually](#installing-manually)
- [Uninstalling](#uninstalling)
- [Updating](#updating)
- [Environments](#environments)
- [Packages](#packages)
- [Packages With C Code](#packages-with-c-code)




## Installing

If you already installed Io, there is a big chance you installed Eerie as well.
To check it, run:

```
$ eerie -v
```

In your terminal. If Eerie installed correctly, it'll print Eerie's version. If
you instead getting something like:

```
zsh: command not found: eerie
```

Follow the instruction in [Installing Manually](#installing-manually).


### Installing Manually

First of all, you should be sure that Eerie isn't installed. For Linux and macOS
it's in `$HOME/.eerie` by default, for Windows it's
`CMAKE_INSTALL_PREFIX\eerie`. If it's there, try to add the required path into
your *.shellrc* file (i.e. `~/.bashrc` for Bash, `~/.zshrc` for ZSH):

```
export EERIEDIR=$HOME/.eerie
export PATH=$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin
```
    
Then reload your terminal.

If your system clean from Eerie and you want to install from ground-up:

1. Clone Eerie repo with `git clone https://github.com/IoLanguage/eerie.git`
2. Change directory to Eerie repo (`cd eerie`)
3. On Linux or macOS run:
```
$ . ./install_unix.sh
```

On Windows, run:

```
$ io setup.io
```

The scripts understand the next options:

- `--dev` to install Eerie from a local directory, so Eerie will remember the
  path for its sources and you'll be able to update it easily calling `eerie
  selfUpdate`.
- `--shrc=<path>` path to your shell config (for example
  `--shrc=~/.bash_profile` or `--shrc=~/.zshrc`). Without this flag
  `~/.profile`, `~/.bash_profile` and `~/.zshrc` will be updated automatically
  on unix systems and no files will be updated on Windows.
- `--notouch` with this flag the script will not touch any config files on your
  system. If you use it, you should be sure that `EERIEDIR` environment variable
  is set to Eerie directory and is available during sessions, otherwise Eerie
  will not work. You should also export your `PATH` with: `$EERIEDIR/base/bin`
  and `$EERIEDIR/activeEnv/bin`.




## Uninstalling

To uninstall Eerie just remove it's directory. By default it's `$HOME/.eerie` on
Linux and macOS, and `CMAKE_INSTALL_PREFIX\eerie` on Windows.




## Updating

To update Eerie run:

```
$ eerie selfUpdate
```




## Environments

Eerie packages are installed globally for the current user. That means that
instead of packages stored in a directory inside your project (like with NPM,
for example), packages you install are available in any project.

While it keeps your system clean from duplicated packages, it introduces an
issue, when you need different versions of the same package for different
projects. To prevent it, Eerie uses **Environments**. An **Environment** is an
isolated collection of packages. You can easily create as many environments as
you wish. It's recommended to create an environment for each project.

Eerie has next commands to work with environments:

- `eerie env:active`
  print the name of the current environment;
  
- `eerie env:list` (or `eerie envs`) 
  list available environments;

- `eerie env:create <name>` 
  create a new environment;

- `eerie env:activate <name>` (or `eerie activate <name>`)
  activate the environment with the given name;

- `eerie env:remove <name>`
  remove the environment with the given name.




## Packages

To better understand Eerie packages, we first look into a package structure.

First, we create a new package **Foo**:

```
$ eerie pkg:create Foo
```

Now let's look at what we got:
```
$ tree Foo
Foo
├── README.md
├── bin
├── hooks
├── io
│   └── Foo.io
├── package.json
└── source

4 directories, 3 files
```

The entry-point of your package is `Foo.io` file.

`bin/` directory contains scripts, which you can use as any other binaries in
your terminal. Eerie itself is a package with a binary `eerie`. So using Eerie,
you can distribute not only packages, but also programs, written in Io.

`hooks/` is a set of optional scripts, which run before or after downloading,
installing and updating of your package. If you put here scripts named either:
**beforeDownload**, **afterDownload**, **beforeInstall**, **afterInstall**,
**beforeUpdate** or **afterUpdate**; it will run in an appropriate time.

`package.json` is the package's manifest. It's the file, which contains
description of your package and dependencies it has.

`source/` is a directory, where stored C source files of your package (if your
package has native code).

Let's add some dependency to our package. We change `package.json` file so it
looks like this:

```
{
  "name":         "Foo",
  "version":      "0.1.0",
  "description":  "",
  "author":       "",
  "website":      "",
  "readme":       "README.md",
  "protos":       ["Foo"],
  "dependencies": {
    "libs":     [],
    "headers":  [],
    "protos":   [],
    "packages": ["https://github.com/bekkopen/jasmineio.git"]
  }
}
```

And we install [jasmineio](https://github.com/bekkopen/jasmineio), to make it
available in our environment:

```
$ eerie install https://github.com/bekkopen/jasmineio.git
```

Now, when someone will install **Foo**, they'll get **jasmineio** installed as
well. So you don't need to instruct the users of your package, which packages
they need to make it work. You can also specify native libraries ("libs") and
headers ("headers").

Let's look at available commands to work with packages:

- `eerie pkg:create <name> <path>`
  Creates an empty package structure. If <path> is omitted, new directory will
  be created in current working directory.

- `eerie pkg:doc <name>`
  Opens documentation for the package in the browser.
  Opens Eerie documentation, if package name isn't specified.

- `eerie pkg:hook <hookName> <packageName>`
  Runs a hook with name at first argument for the package with name at the
  second one.

- `eerie pkg:info <name>`
  Shows description of a package.

- `eerie pkg:install <uri>` (or `eerie install <uri>`)
  Installs a new package.

- `eerie pkg:list` (or `eerie pkgs`)
  Lists all packages installed within current env.

- `eerie pkg:remove <name>` (or `eerie remove <name>`)
  Removes the package.

- `eerie pkg:update <name>` (or `eerie update <name>`)
  Updates the package and all of its dependencies.

- `eerie pkg:updateAll`
  Updates all packages within current env.




## Packages With C Code

Writing Eerie packages using C is better explained in
[NullAddon](https://github.com/IoLanguage/NullAddon). It also may be considered
a template for native packages.

Basically, except of the package code itself, you need a `build.io` file in
which you can rewrite `AddonBuilder` to represent a receipt for your package.
Here is the contents of `build.io` of the **NullAddon**:

```Io
# This clone is _required_ for the build process to function correctly.
# However, it doesn't actually have to do anything at all.  Therefore,
# I've commented out the stuff that you'd normally see, since it really
# doesn't depend on anything not already provided in the NullAddon
# software.

AddonBuilder clone do(
/*
 	if(list("cygwin", "mingw", "windows") contains(platform),
 		dependsOnLib("C-library-name-here")
 		dependsOnHeader("C-header-file-here.h")
 	)
 
 	if(list("darwin", "linux", "netbsd") contains(platform),
 		dependsOnLib("C-library-name-here")
 		dependsOnHeader("C-header-file-here.h")
 	)
 
 	debs    atPut("package-name-here", "DistroPackageNameHere")
 	ebuilds atPut("package-name-here", "DistroPackageNameHere")
 	pkgs    atPut("package-name-here", "DistroPackageNameHere")
 	rpms    atPut("package-name-here", "DistroPackageNameHere")
*/
)
```
