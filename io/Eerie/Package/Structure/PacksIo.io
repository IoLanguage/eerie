//metadoc PacksIo category Package
//metadoc PacksIo description Represents `packs.io` file.
PacksIo := Object clone do (

    //doc PacksIo struct Get the `Package Structure`.
    struct := nil

    //doc PacksIo file Get `packs.io` `File`.
    file := method(self struct root fileNamed("packs.io"))

    _descs := nil

    /*doc PacksIo with(Structure) 
    Init `PacksIo` with `Structure`.*/
    with := method(struct,
        klone := self clone
        klone struct = struct
        _descs := doFile(klone file path) ifNilEval(Map clone)
        klone _descs := self deserializeDescs(_descs)
        klone)

    _deserializeDescs := method(descs,
        result := Map clone
        descs foreach(key, value,
            result atPut(key, DepDesc fromSerializedObj(value)))

        result)

    //doc PacksIo missing Returns list of missing dependencies.
    missing := method(
        # TODO
    )

    /*doc PacksIo abandoned
    Returns list of abandoned dependencies (i.e. those which are no more in
    `eerie.json`).*/
    abandoned := method(
        # TODO
    )

    /*doc PacksIo generate
    Generate the file.*/
    generate := method(
        self struct manifest packs foreach(dep,
            self addDesc(DepDesc with(dep, self struct)))

        self store)

    //doc PacksIo store Write the file.
    store := method(self file setContents(self _descs serialized))

    /*doc PacksIo addDesc(desc) 
    Add dependency description. If it's already in the map, replaces it with the
    passed one.*/
    addDesc := method(desc, self _descs atPut(desc name, desc))

    /*doc PacksIo removeDesc(name) 
    Remove dependency description by name (`Sequence`).*/
    removeDesc := method(name, self _descs removeAt(name))

)

//metadoc DepDesc category Package
/*metadoc DepDesc description
Description of an installed dependency. Serialization of this type is stored in
`packs.io`.*/
DepDesc := Object clone do (

    //doc DepDesc name Get name.
    //doc DepDesc setName(Sequence) Set name.
    name ::= nil

    //doc DepDesc version Get version (`Sequence`).
    //doc DepDesc setVersion Set version (`Sequence`).
    version ::= nil

    //doc DepDesc children Get children of this `DepDesc` (`Map`).
    //doc DepDesc setChildren(Map) Set children.
    children ::= nil

    //doc DepDesc parent Get parent `DepDesc`. Can return `nil`.
    //doc DepDesc setParent(DepDesc) Set parent.
    parent ::= nil 

    //doc DepDesc recursive Get a boolean whether `DepDesc` is recursive.
    //doc DepDesc setRecursive(boolean) `DepDesc recursive` setter.
    recursive ::= false

    //doc DepDesc serialized Get serialized version of `DepDesc` (`Sequence`).
    serialized := method(
        obj := Object clone
        obj name := self name
        obj version := self version
        obj children := self children
        # obj parent := self parent
        obj recursive := self recursive
        obj serialized)

    /*doc DepDesc deserialize(Sequence) 
    Deserializes `DepDesc` from the given `Sequence`.

    Note, the serialized `DepDesc` is considered the top level `DepDesc` so its
    `parent` is always `nil`.*/
    deserialize := method(seq,
        obj := doString(seq)
        self fromSerializedObj(obj))

    /*doc DepDesc fromSerializedObj(Object, DepDesc)
    Init `DepDesc` from a serialized `Object`.

    The second argument is optional `parent` for this `DepDesc`.*/
    fromSerializedObj := method(obj, parent,
        result := DepDesc clone
        result name = obj name
        result version = obj version
        result recursive = obj recursive
        result parent = parent
        result children = result _deserializeChildren(obj)
        result)

    _deserializeChildren := method(obj,
        if (obj children isNil, return)
        children := Map clone
        obj children foreach(key, value,
            children atPut(key, self fromSerializedObj(value, self)))
        children)

    /*doc DepDesc with(dep, struct, parent) 
    Recursively initializes `DepDesc` from `Package Dependency`, 
    `Package Structure` and parent `DepDesc` (can be `nil`).*/
    with := method(dep, struct, parent,
        depRoot := struct packRootFor(dep name)

        if (depRoot exists not,
            Exception raise(DependencyNotInstalledError with(dep name)))

        version := self _installedVersionFor(dep, depRoot)

        packDir := struct packFor(dep name, version)

        if (packDir exists not, 
            Exception raise(DependencyNotInstalledError with(dep name)))

        result := DepDesc clone \
            setName(dep name) \
                setVersion(version asSeq) \
                    setParent(parent)
                    
        result _collectChildren(packDir, struct))

    _installedVersionFor := method(dep, depRoot,
        versions := self _versionsInDir(depRoot)
        dep version highestIn(versions))

    # get list of `SemVer` in a package dir
    _versionsInDir := method(dir,
        dir directories map(subdir, SemVer fromSeq(subdir name)))

    _hasAncestor := method(desc,
        if (self parent isNil, return false)

        if (self parent name == desc name and(
            self parent version == desc version),
            return true,
            return self parent _hasAncestor(desc)))

    _collectChildren := method(packDir, struct,
        if (self _hasAncestor(self), return self setRecursive(true))

        deps := Package with(packDir path) struct manifest packs

        deps foreach(dep,
            self addChild(DepDesc with(dep, struct, self)))
    
        self)

    //doc DepDesc addChild(DepDesc) Adds a child.
    addChild := method(desc,
        if (self children isNil, self setChildren(Map clone))
        self children atPut(desc name, desc))

    //doc DepDesc removeChild(Sequence) Removes a child by its name.
    removeChild := method(name, 
        if (self children isNil, return)
        self children removeAt(name))

)

# PacksIo error types
DepDesc do (

    DependencyNotInstalledError := Eerie Error clone setErrorMsg(
        "Dependency \"#{call evalArgAt(0)}\" is not installed.")

)
