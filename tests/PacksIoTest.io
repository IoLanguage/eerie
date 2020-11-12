Importer addSearchPath("io/Eerie/Package/Structure")
Importer addSearchPath("io/Eerie/Package/Structure")

DepDescTest := UnitTest clone do (

    Manifest
    PacksIo

    testInit := method(
        package := Package with("tests/installed/AFakePack")
        descs := package struct manifest packs map(dep, 
            DepDesc with(dep, package struct))
        expected := list("AFakePack", "BFakePack")
        assertEquals(expected, descs at(0) children keys sort)

        expected = list("AFakePack", "CFakePack")
        assertEquals(expected, descs at(1) children keys sort)

        descs foreach(desc, 
            desc children foreach(key, child, 
                assertEquals(child parent name, desc name)))

        assertTrue(
            descs at(0) children \
                at("BFakePack") children \
                    at("CFakePack") recursive)

        assertTrue(
            descs at(0) children \
                at("AFakePack") children \
                    at("CFakePack") recursive)

        assertTrue(
            descs at(1) children \
                at("AFakePack") children \
                    at("BFakePack") recursive)

        assertTrue(
            descs at(1) children \
                at("CFakePack") children \
                    at("BFakePack") recursive))

    testSerialization := method(
        package := Package with("tests/installed/AFakePack")
        desc := DepDesc with(
            package struct manifest packs at(0),
            package struct)

        de := DepDesc deserialize(desc serialized)
        assertEquals(de name, desc name)
        assertEquals(de version, desc version)
        assertEquals(de recursive, desc recursive)
        assertEquals(de children keys, desc children keys)

        self _checkParents(de)

        de children foreach(key, child,
            assertEquals(child parent, de)

            child children foreach(key, ch,
                assertEquals(ch parent, child)))

        assertEquals(de serialized, desc serialized))

    _checkParents := method(de,
        de children ?foreach(key, child,
            self _checkParents(child)
            assertEquals(child parent, de)))

)
