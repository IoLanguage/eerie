//metadoc TransactionAction category API
//metadoc TransactionAction description

TransactionAction := Object clone do(
  named := method(name_,
    name_ = name_ .. "Action"
    self instances foreachSlot(slotName, action,
      (slotName == name_) ifTrue(
        return(action)
      )
    )

    Eerie MissingTransactionException raise(name_)
  )

  exists := method(name_,
    self named(name_) != nil)

  pkg ::= nil

  with := method(pkg_,
    self clone setPkg(pkg_)
  )

  //doc TransactionAction asVerb
  asVerb := method(
    self asVerb = self type makeFirstUppercase .. "ing")

  name := method(
    self name = self type exSlice(0, "Action" size + 1))

  //doc TransactionAction prepare
  prepare := method(false)

  //doc TransactionAction execute
  execute := method(false)
)

TransactionAction instances := Object clone do(
  doRelativeFile("TransactionActions/InstallAction.io")
  doRelativeFile("TransactionActions/UpdateAction.io")
  doRelativeFile("TransactionActions/RemoveAction.io")
)

