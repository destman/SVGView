/*
 *  Logger.h
 *  AgileSpeed
 *
 *  Created by destman on 8/31/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#if DEBUG

#ifdef __cplusplus 
extern "C" {
#endif
	
#ifdef __OBJC__
void dbgLog(NSString *tmpl,...);
#endif

void dbg_log(const char *tmpl,...);

#ifdef __cplusplus 
}
#endif
	
#else

#define dbgLog(...);
#define dbg_log(...);

#endif
