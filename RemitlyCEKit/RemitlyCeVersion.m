#import "RemitlyCeVersion.h"

#ifndef RemitlyCE_VERSION
#error "RemitlyCE_VERSION is not defined: add -DRemitlyCE_VERSION=... to the build invocation"
#endif

// The following two macros supply the incantation so that the C
// preprocessor does not try to parse the version as a floating
// point number. See
// https://www.guyrutenberg.com/2008/12/20/expanding-macros-into-string-constants-in-c/
#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

NSString* RECEVersion(void) {
  return [NSString stringWithUTF8String:(const char* const)STR(RemitlyCE_VERSION)];
}
