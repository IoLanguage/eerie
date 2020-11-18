# Generates IoPackNameInit.c file which contains code for initialization of the
# protos defined by the sources
InitFileGenerator := Object clone do (
    package := nil

    # the output file
    output := lazySlot(
        path := "source/Io#{self package struct manifest name}Init.c" interpolate
        self package struct root fileNamed(path))

    # directory with Io code
    ioCodeDir := method(self package struct root directoryNamed("io"))

    # io files inside `io` directory
    # FIXME this should be `recursiveFileOfTypes(list("io"))`, but the generated
    # code may need to be changed too
    ioFiles := method(self ioCodeDir filesWithExtension("io"))
    
    # whether the compiled package should embed io code into the library
    embedIoCode ::= false

    # the initializer
    with := method(pkg, 
        klone := self clone
        klone package = pkg
        klone)

    # generates the file
    generate := method(
        self output remove create open

        self _writeHead

        ioCFiles := self _ioCFiles

        extraFiles := self _extraFiles

        self _writeDeclarations(ioCFiles, extraFiles)

        if (Eerie platform == "windows",
            self output write("__declspec(dllexport)\n"))

        self _writeInitFunction(ioCFiles, extraFiles)
        self output close)

    _writeHead := method(
        self output write("""|
// This file is generated automatically. If you want to customize it, you should
// add setShouldGenerateInit(false) to the build.io, otherwise it will be
// rewritten on the next build.
//
// The slot setting order is not guaranteed to be alphabetical. If you want a
// slot to be set before another slot you can add a comment line like:
//
// docDependsOn("SlotName")
//
// This way the slot "SlotName" will be set before the current slot.
|
#include "IoState.h"
#include "IoObject.h" 
            """ fixMultiline, "\n\n"))

    # Get files like IoName.c
    _ioCFiles := method(
        sources := self package struct source files

        files := sources select(name beginsWithSeq("Io")) \
            select(f, f name endsWithSeq(".c") or f name endsWithSeq(".cpp")) \
                select(name containsSeq("Init") not) \
                    select(name containsSeq("_") not)

        # sort slot definitions considering docDependsOn
        sorted := files clone

        files foreach(file,
            if (depName := file open \
                    readLines detect(containsSeq("docDependsOn")),

                file close

                depFileName := \
                    "Io" .. depName afterSeq("(\"") beforeSeq("\")") .. ".c"
                depFile := sorted detect(name == depFileName)
                sorted remove(file)
                sorted insertAfter(file, depFile)))

        sorted)

    # Get files like IoName_doing.c
    _extraFiles := method(
        package struct source files \
            select(name beginsWithSeq("Io")) \
                select(name endsWithSeq(".c")) \
                    select(name containsSeq("Init") not) \
                        select(name containsSeq("_")))

    _writeDeclarations := method(sources, extras,
        sources foreach(f,
            self output write(
                "IoObject *#{f baseName}_proto(void *state);\n" interpolate))

        extras foreach(f,
            self output write(
                "void #{f baseName}Init(void *context);\n" interpolate)))

    _writeInitFunction := method(sources, extras,
        self output write(
            "\nvoid #{self output baseName}(IoObject *context)" interpolate)

        self output write(" {\n")

        if(sources isEmpty not,
            self output write(
                "\tIoState *self = IoObject_state((IoObject *)context);\n\n"))

        sources foreach(f,
            protoName := f baseName asMutable removePrefix("Io")
            self output write("\tIoObject_setSlot_to_(context, SIOSYMBOL(\"" ..\
                "#{protoName}\"), #{f baseName}_proto(self));\n\n" interpolate))

        extras foreach(f,
            self output write("\t#{f baseName}Init(context);\n" interpolate))

        if(self ioCodeDir and self embedIoCode,
            self ioFiles foreach(f, self output write(_codeForIoFile(f))))

        self output write("}\n"))

    _codeForIoFile := method(file,
        code := Sequence clone
        if (file size < 1, return code)

        code appendSeq("\t{\n\t\tchar *s = ")
        code appendSeq(file contents splitNoEmpties("\n") map(line,
            "\"#{line escape}\\n\"" interpolate) join("\n\t\t"))
        code appendSeq(
            ";\n\t\tIoState_on_doCString_withLabel_(self, context, s, \"" ..
                "#{file name}\");\n" interpolate)
        code appendSeq("\t}\n\n"))

    # better indentation for multiline strings
    Sequence fixMultiline := method(
        self splitNoEmpties("\n") map(split("|") last) join("\n") strip)
)
