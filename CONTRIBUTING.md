# Contents

- [Contributing](#contributing)
    - [Pull Requests](#pull-requests)
    - [Io Style Guide](#io-style-guide)
        - [Document Structure](#document-structure)
        - [Naming](#naming)
        - [Indentation](#indentation)
        - [Line Width](#line-width)
        - [Comments](#comments)
        - [`if` Statements](#if-statements)

# Contributing

This document describes rules, which we all should follow to keep the code base
maintainable and consistent. It's important to follow these rules and a PR will
not be merged until they're satisfied.




## Pull Requests

Please **describe what changes your PR has**. If it's related to an issue,
please **link this issue** in the PR.

Any fixes and new features **should be covered by tests**. To make it easier for
maintainers and contributors, stick the rule that you should prove it works
using tests.




## Io Style Guide


### Document Structure

If it's possible and clear to keep all items of a module in a single file - do
this. The fewer files, the better. But until it's not a thousands of lines file
where you barely can navigate.

The public modules should be started with metadoc comments.

```Io
//metadoc Proto category Name
/*metadoc Proto description
Description of the module.*/
```

The proto definition should be started with member variables (including getters
and setters) followed by initializers and then with functions ordered by their
introduction in the code.

For example, if you write a method `foo`, which uses a method `bar` followed by
`baz`, you should write them in the same order:

**CORRECT**
```Io
    foo := method(
        self _bar
        self _baz)

    _bar := method("hello" println)

    _baz := method("world" println)
```

**WRONG**
```Io
    _baz := method("world" println)

    _bar := method("hello" println)

    foo := method(
        self _bar
        self _baz)
```


### Naming

All member items should be anticipated with `self` keyword to make it clear
where they come from.

All private members should be started with `_` character:

```Io
SomeProto := Object clone do (
    _privateSlot := 42

    _privateMethod := method(self _privateSlot println)
)
```


### Indentation

The tab should be equal to **4 spaces**.

We use style when you close a bracket on the last line. For example:

**CORRECT**
```Io
    _buildStaticLib := method(
        Logger log("Building #{self _staticLinkerCommand outputName}")

        self staticLibBuildStarted

        self package dir directoryNamed("_build/lib") createIfAbsent
        System sh(self _staticLinkerCommand asSeq))
```

**WRONG**
```Io
    _buildStaticLib := method(
        Logger log("Building #{self _staticLinkerCommand outputName}")

        self staticLibBuildStarted

        self package dir directoryNamed("_build/lib") createIfAbsent
        System sh(self _staticLinkerCommand asSeq)
    )
```

But this rule doesn't apply to the `do` statement:

**CORRECT**
```Io
ProtoName := Object clone do (

    someMethod := method("hello" println)
    ...
)
```

**WRONG**
```Io
ProtoName := Object clone do (

    someMethod := method("hello" println)
    ...)
```

Also, notice a space after the `do` keyword. There should be a blank line inside
after start and before the end of the `do` block.


### Line Width

The line width is **80 characters**.


### Comments

For normal comments use hash-comments (i.e. `# comments`). Use slash-comments
(i.e. `// a comment` and `/*a comment*/`) only for documentation of the public
API (i.e. `//doc Proto method Description` or `/*doc Proto method Description*/`
).

All public modules should start with metadoc comments with category and
description.

Use markdown styling inside documentation comments. For code protos and their
members use inline code style.

All public **API should be documented**. It's good if private functions are
commented too.


### `if` Statements

Use the short form of if statement for small blocks, where it has a single case
or it's very easy to separate the cases. Also, use a space after `if`, `then`,
`elseif` and `else` keywords. Examples:

**CORRECT**
```Io
value := if (test, 1, 0)

if (test, Exception raise(SomeError with("message")))

if (test, 
    Exception raise(AnotherError with("message")),
    return "ok")
```

**WRONG**
```Io
if (test, 
    Exception raise(AnotherError with("message"))
    ,
    return "ok")

if (test, 
    Exception raise(AnotherError with("message"))
    ... a lot of code,
    return "ok")
```

For bigger code blocks use the full form with `then`, `elseif` and `else`
keywords.
