Importer addSearchPath("io")
Importer addSearchPath("io/Eerie")

DatabaseTest := UnitTest clone do (

    Database dir := Directory with("tests/db")

    testValueFor := method(
        db := Database clone
        pkgName := "AFakeAddon"
        assertEquals(pkgName, db valueFor("AFakeAddon", "name"))
        assertEquals(
            "tests/_addons/AFakeAddon", 
            db valueFor("AFakeAddon", "url")))

)
