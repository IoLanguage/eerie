Test := Object clone do (

    test := method(true)

    depsTest := method(
        AFakePack Test test and DFakePack Test test and CFakePack Test test)

)
