#ifndef IODEP_DEFINED
#define IODEP_DEFINED 1

#include "IoObject.h"

typedef IoObject IoDep;

IoDep *IoDep_proto(void *state);
IoDep *IoDep_rawClone(IoDep *self);
IoDep *IoDep_new(void *state);
void IoDep_free(IoDep *self);

#endif
