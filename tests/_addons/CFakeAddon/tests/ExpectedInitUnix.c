// This file is generated automatically. If you want to customize it, you should
// add setShouldGenerateInit(false) to the build.io, otherwise it will be
// rewritten on the next build.
//
// The slot setting order is not guaranteed to be alphabetical. If you want to a
// slot to be set before another slot you can add a comment line like:
//
// docDependsOn("SlotName")
//
// This way the slot "SlotName" will be set before the current slot.

#include "IoState.h"
#include "IoObject.h"

IoObject *IoTest_proto(void *state);
IoObject *IoDep_proto(void *state);

void IoCFakeAddonInit(IoObject *context) {
	IoState *self = IoObject_state((IoObject *)context);

	IoObject_setSlot_to_(context, SIOSYMBOL("Test"), IoTest_proto(self));

	IoObject_setSlot_to_(context, SIOSYMBOL("Dep"), IoDep_proto(self));

}
