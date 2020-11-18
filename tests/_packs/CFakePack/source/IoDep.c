#include <stdio.h>
#include "IoState.h"

#include "IoDep.h"

// docDependsOn("Test")

static const char *protoId = "Dep";

IoTag *IoDep_newTag(void *state)
{
	IoTag *tag = IoTag_newWithName_(protoId);

	IoTag_state_(tag, state);

	IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoDep_free);

	IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoDep_rawClone);

	return tag;
}

IoDep *IoDep_proto(void *state)
{
	IoObject *self = IoObject_new(state);
	IoObject_tag_(self, IoDep_newTag(state));
	
	IoState_registerProtoWithFunc_(state, self, IoDep_proto);
	
	{
		IoMethodTable methodTable[] = {
		{NULL, NULL},
		};
		
		IoObject_addMethodTable_(self, methodTable);
	}

    return self;
}

IoDep *IoDep_rawClone(IoDep *proto)
{
	IoDep *self = IoObject_rawClonePrimitive(proto);

	return self;
}

IoDep *IoDep_new(void *state)
{
	IoObject *proto = IoState_protoWithId_(state, protoId);
	return IOCLONE(proto);
}

void IoDep_free(IoDep *self) 
{ 
	free(IoObject_dataPointer(self));
}
