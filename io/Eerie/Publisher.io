//metadoc Publisher category API
/*metadoc Publisher description 
The purpose of this proto is to prepare to and publish a package. Currently it's
able to prepare (`Publisher release`) only.*/

Publisher := Object clone do (

    //doc Publisher package The package wich the publisher will publish/release.
    //doc Publisher setPackage `Publisher package` setter.
    package ::= nil

    /*doc Publisher with(Package) 
    Use this initializer to instantiate `Publisher`.*/
    with := method(pkg, self clone setPackage(pkg))

    /*doc Publisher publish 
    **UNIMPLEMENTED** Prepares (`Publisher release`) and publishes the `package`
    in Eerie database.*/
    publish := method(
        self release
        # TODO
        # unimplemented
    )

    /*doc Publisher publish
    This method validates the `package` and creates a new git tag for release.

    This should be done before you publish the package in Eerie database.*/
    release := method(
        self _checkPackageSet
        self _validate
        self _checkHasGitChanges
        self _addGitTag

        Logger log(
            "🎉 [[magenta;Successfully released [[bold;#{self package name} " ..
            "v#{self package version asSeq}[[reset magenta;![[reset;\n\n" .. 
            "[[reset;Now publish it in Eerie database.\n" .. 
            "Check " .. 
            "[[green;https://github.com/IoLanguage/eerie-db[[reset; " .. 
            "for instructions.\n\n" .. 
            "Oh, and don't forget to git push your changes!",
            "output"))

    _checkPackageSet := method(
        if (self package isNil, Exception raise(PackageNotSetError with("")))
    )

    _validate := method(
        # TODO check whether the package satisfies all the requirements for
        # published packages:
        # - version is newer then the previous one (first check db, 
        #   then git tags)
        # - has non-empty README.md
        # - has LICENSE
        # - ...?
    )

    _checkHasGitChanges := method(
        # TODO
        Exception raise(HasGitChangesError with(self package name))
    )

    _addGitTag := method(
        name := "v" .. self package version asSeq
        self _checkGitTagExists(name)

        Eerie sh(
            "git tag -a #{name} -m " ..
            "'New release generated automatically by Eerie Publisher'",
            true, 
            self package dir path))

    _checkGitTagExists := method(tag,
        # TODO
        Exception raise(GitTagExistsError with(tag, self package name)))

)

# Publisher error types 
Publisher do (

    PackageNotSetError := Eerie Error clone setErrorMsg("Package doesn't set.")

    GitTagExistsError := Eerie Error clone setErrorMsg(
        "Git tag #{call evalArgAt(0)} already exists in package " .. 
        "#{call evalArgAt(1)}")

    HasGitChangesError := Eerie Error clone setErrorMsg(
        "Package \"#{call evalArgAt(0)}\" has uncommitted changes.\n" .. 
        "Please, add and commit them first.")

)
