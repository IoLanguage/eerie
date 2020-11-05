//metadoc Action category API
/*metadoc Action description
Abstract proto for actions.*/

Action := Object clone do (

    //doc Action name Get action name.
    name := lazySlot(self type)

    /*doc Action asVerb 
    Get a verb version of the action (i.e. "Installing" for "Install" etc.).*/
    asVerb := lazySlot(self name .. "ing")

    //doc Action package Get the `Package` on which this action operates.
    /*doc Action setPackage(Package) 
    Set the `Package` on which this action operates.*/
    package ::= nil

    # specific dependency (`Package Dependency`) to which this actions is
    # related
    _dependency := nil

    /*doc Action named(name)
    Get an instance of action for specified `name` (`Sequence`).*/
    named := method(name,
        self instances foreachSlot(slotName, action,
            if (slotName == name, return action))

        Exception raise(UnknownActionError with(name)))

    /*doc Action with(Package Dependency) 
    Init action with the given `Package Dependency`.*/
    with := method(dep, 
        klone := self clone
        klone _dependency = dep
        klone)

    //doc Action prepare Prepare action for execution.
    prepare := method(false)

    //doc Action execute Execute action.
    execute := method(false)

)

Action instances := Object clone do (

    doRelativeFile("actions/Install.io")
    
    doRelativeFile("actions/Update.io")

    doRelativeFile("actions/Remove.io")

)

# Error types
Action do (

    //doc Action UnknownActionError
    UnknownActionError := Eerie Error clone setErrorMsg(
        "The '#{call evalArgAt(0)}' action is unknown.")

)

