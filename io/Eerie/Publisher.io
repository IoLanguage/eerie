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
        self _checkVersion
        self _checkDescription
        self _checkReadme
        self _checkLicense)

    _checkVersion := method(
        self _checkVersionNewer
        self _checkVersionShortened)

    _checkVersionNewer := method(
        verSeq := Database valueFor(self package name, "version")
        previous := if (verSeq isNil,
            self package highestVersionFor,
            SemVer fromSeq(verSeq))

        if (previous isNil, return)

        if (previous >= self package version, 
            Exception raise(
                VersionIsOlderError with(
                    self package name, 
                    self package version originalSeq,
                    previous originalSeq))))

    _checkVersionShortened := method(
        if (self package version isShortened,
            Exception raise(
                VersionIsShortened with(self package version asSeq))))

    _checkDescription := method(
        desc := self package config at("description")
        if (desc isNil or desc isEmpty, 
            Exception raise(NoDescriptionError with(""))))

    _checkReadme := method(
        path := self package config at("readme")
        if (self _hasRequiredFile(path) not, 
            Exception raise(ReadmeError with(""))))

    _hasRequiredFile := method(path,
        if (path isNil or path isEmpty, return false)

        file := File with(self package struct root path .. "/" .. path)
        
        if (file exists not or file ?contents isEmpty, 
            return false)

        return true)

    _checkLicense := method(
        path := self package config at("license")
        if (self _hasRequiredFile(path) not, 
            Exception raise(LicenseError with(""))))

    _checkHasGitChanges := method(
        cmdOut := System sh(
            "git status --porcelain", true, self package struct root path)
        # filter out *-stdout and *-stderr files created by System runCommand
        res := cmdOut stdout split("\n") select(seq,
            seq endsWithSeq("-stdout") not and seq endsWithSeq("-stderr") not)
        if (res isEmpty not, 
            Exception raise(HasGitChangesError with(self package name))))

    _addGitTag := method(
        self _checkGitTagExists

        System sh(
            "git tag -a #{self gitTag} -m " ..
            "'New release generated automatically by Eerie Publisher'",
            false, 
            self package struct root path))

    _checkGitTagExists := method(
        cmdOut := System sh("git tag", true, self package struct root path)

        if (cmdOut stdout split("\n") contains(self gitTag),
            Exception raise(
                GitTagExistsError with(self gitTag, self package name))))

    _promptPush := method(
        if (self shouldPush isNil not, return)
        
        stream := File standardInput

        answer := "-"
        while (answer isEmpty not and answer != "y" and answer != "n",
            answer = stream readLine(
                "Do you want to push the changes? [Yn]\n") asLowercase)

        self setShouldPush(answer isEmpty or answer == "y"))

    _gitPush := method(
        System sh("git push origin #{self gitTag}", 
            false, 
            self package struct root path))

)

# Publisher error types 
Publisher do (

    PackageNotSetError := Eerie Error clone setErrorMsg("Package doesn't set.")

    VersionIsOlderError := Eerie Error clone setErrorMsg(
        "The release version \"#{call evalArgAt(1)}\" " ..
        "of package \"#{call evalArgAt(0)}\" " ..
        "should be higher than the previous version (\"#{call evalArgAt(2)}\")")

    VersionIsShortened := Eerie Error clone setErrorMsg(
        "The release version shouldn't be shortened.")

    NoDescriptionError := Eerie Error clone setErrorMsg(
        "Published packages should have \"description\" in " ..
        "#{Package Manifest name}.")

    ReadmeError := Eerie Error clone setErrorMsg(
        "README file is required for published packages and shouldn't be " ..
        "empty.")

    LicenseError := Eerie Error clone setErrorMsg(
        "LICENSE file is required for published packages and shouldn't be " ..
        "empty.")

    GitTagExistsError := Eerie Error clone setErrorMsg(
        "Git tag #{call evalArgAt(0)} already exists in package " .. 
        "#{call evalArgAt(1)}")

    HasGitChangesError := Eerie Error clone setErrorMsg(
        "Package \"#{call evalArgAt(0)}\" has uncommitted changes.\n" .. 
        "Please, add and commit them first.")

)
