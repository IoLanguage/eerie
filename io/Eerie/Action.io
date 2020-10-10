//metadoc Action category API
//metadoc Action description

Action := Object clone do(
    named := method(name_,
        self instances foreachSlot(slotName, action,
            (slotName == name_) ifTrue(
                return(action)))

        Eerie MissingTransactionException raise(name_))

    exists := method(name_, self named(name_) != nil)

    pkg ::= nil

    with := method(pkg_, self clone setPkg(pkg_))

    //doc Action asVerb
    asVerb := method(self asVerb = self type makeFirstUppercase .. "ing")

    name := method(self name = self type exSlice(0, "Action" size + 1))

    //doc Action prepare
    prepare := method(false)

    //doc Action execute
    execute := method(false)
)

Action instances := Object clone do(
    doRelativeFile("actions/Install.io")
    doRelativeFile("actions/Update.io")
    doRelativeFile("actions/Remove.io")
)
