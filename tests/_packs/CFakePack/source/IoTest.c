#include <stdio.h>
#include "IoState.h"

#include "IoTest.h"

static const char *protoId = "Test";

IoTag *IoTest_newTag(void *state)
{
	IoTag *tag = IoTag_newWithName_(protoId);

	IoTag_state_(tag, state);

	IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoTest_free);

	IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoTest_rawClone);

	return tag;
}

IoTest *IoTest_proto(void *state)
{
	IoObject *self = IoObject_new(state);
	IoObject_tag_(self, IoTest_newTag(state));
	
	IoState_registerProtoWithFunc_(state, self, IoTest_proto);
	
	{
		IoMethodTable methodTable[] = {
		{NULL, NULL},
		};
		
		IoObject_addMethodTable_(self, methodTable);
	}

    return self;
}

IoTest *IoTest_rawClone(IoTest *proto)
{
	IoTest *self = IoObject_rawClonePrimitive(proto);

	return self;
}

IoTest *IoTest_new(void *state)
{
	IoObject *proto = IoState_protoWithId_(state, protoId);
	return IOCLONE(proto);
}

void IoTest_free(IoTest *self) 
{ 
	free(IoObject_dataPointer(self));
}
