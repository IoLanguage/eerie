DatabaseTest := UnitTest clone do (

    testValueFor := method(
        db := Database clone
        pkgName := "AFakeAddon"
        assertEquals(pkgName, db valueFor("AFakeAddon", "name"))
        assertEquals(
            "tests/_addons/AFakeAddon", 
            db valueFor("AFakeAddon", "url")))

)
