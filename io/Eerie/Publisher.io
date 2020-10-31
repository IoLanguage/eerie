//metadoc Publisher category API
/*metadoc Publisher description 
The purpose of this proto is to prepare to and publish a package. Currently it's
able to prepare (`Publisher release`) only. Publishing is supposed to be done
manually, look https://github.com/IoLanguage/eerie-db for instructions.*/

Publisher := Object clone do (

    //doc Publisher package The package wich the publisher will publish/release.
    //doc Publisher setPackage `Publisher package` setter.
    package ::= nil

    /*doc Publisher gitTag 
    Get git tag name, which will be used for the release.*/
    gitTag := method("v" .. self package version asSeq)

    /*doc Publisher shouldPush 
    Whether git push should be performed after release. `true`, `false` or
    `nil`.

    If it's `nil` the publisher will prompt you during the release process.

    Default is `nil`.*/
    //doc Publisher setShouldPush `shouldPush` setter.
    shouldPush ::= nil

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

    /*doc Publisher release
    This method validates the `package` and creates a new git tag for release.

    This should be done before you publish the package in Eerie database.*/
    release := method(
        self _checkPackageSet
        self validate
        self _checkHasGitChanges
        self _addGitTag
        self _promptPush

        Logger log(
            "🎉 [[magenta;Successfully released [[bold;#{self package name} " ..
            "v#{self package version asSeq}[[reset magenta;![[reset;\n\n" .. 
            "Now publish it in Eerie database.\n" .. 
            "Look [[green;https://github.com/IoLanguage/eerie-db[[reset; " .. 
            "for instructions.")

        if (self shouldPush,
            self _gitPush,
            Logger log(
                "\nOh, and don't forget to \"git push origin #{self gitTag}\"!",
                "output")))

    _checkPackageSet := method(
        if (self package isNil, Exception raise(PackageNotSetError with(""))))

    /*doc Publisher validate
    Check whether the `package` satisfies all the requirements for published
    packages.*/
    validate := method(
        # TODO check whether the package satisfies all the requirements for
        # published packages:
        # - version is newer then the previous one (first check db, 
        #   then git tags)
        #   * shouldn't be shortened as well
        # - has non-empty README.md
        # - has LICENSE
        # - ...?
    )

    _checkHasGitChanges := method(
        # TODO
        Exception raise(HasGitChangesError with(self package name))
    )

    _addGitTag := method(
        self _checkGitTagExists

        Eerie sh(
            "git tag -a #{self gitTag} -m " ..
            "'New release generated automatically by Eerie Publisher'",
            false, 
            self package dir path))

    _checkGitTagExists := method(
        # TODO
        Exception raise(GitTagExistsError with(self gitTag, self package name)))

    _promptPush := method(
        if (self shouldPush isNil not, return)
        
        stream := File standardInput

        answer := "-"
        while (answer isEmpty not and answer != "y" and answer != "n",
            answer = stream readLine(
                "Do you want to push the changes? [Yn]\n") asLowercase)

        self setShouldPush(answer isEmpty or answer == "y"))

    _gitPush := method(
        Eerie sh("git push origin #{self gitTag}", 
            false, 
            self package dir path))

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
