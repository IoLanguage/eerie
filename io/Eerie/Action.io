//metadoc Action category API
/*metadoc Action description
Abstract proto for actions.*/

Action := Object clone do (

    //doc Action name Get action name.
    name := lazySlot(self type)

    /*doc Action asVerb 
    Get a verb version of the action (i.e. "Installing" for "Install" etc.).*/
    asVerb := lazySlot(self name .. "ing")

    /*doc Action package 
    This supposed to be the `Package`, which you get after preparation
    (i.e. downloading and instantiation).*/
    package ::= nil

    # specific dependency (`Package DepDesc`) to which this actions is
    # related
    _dependency := nil

    # parent `Package` for which we doing the action
    _parent := nil

    /*doc Action named(name)
    Get an instance of action for specified `name` (`Sequence`).*/
    named := method(name,
        self instances foreachSlot(slotName, action,
            if (slotName == name, return action))

        Exception raise(UnknownActionError with(name)))

    /*doc Action with(parent, dependency) 
    Init action with the parent `Package` and a dependency description
    (`Package DepDesc`).*/
    with := method(parentPkg, dep, 
        klone := self clone
        klone _parent = parentPkg
        klone _dependency = dep
        klone)

    //doc Action prepare Prepare action for execution.
    prepare := method()

    //doc Action execute Execute action.
    execute := method()

)

Action instances := Object clone do (

    doRelativeFile("actions/InstallDep.io")
    
    doRelativeFile("actions/UpdateDep.io")

)

# Error types
Action do (

    //doc Action UnknownActionError
    UnknownActionError := Eerie Error clone setErrorMsg(
        "The '#{call evalArgAt(0)}' action is unknown.")

)

