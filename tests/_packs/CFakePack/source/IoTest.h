#ifndef IOTEST_DEFINED
#define IOTEST_DEFINED 1

#include "IoObject.h"

typedef IoObject IoTest;

IoTest *IoTest_proto(void *state);
IoTest *IoTest_rawClone(IoTest *self);
IoTest *IoTest_new(void *state);
void IoTest_free(IoTest *self);

#endif
