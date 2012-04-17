/*
 *  Logger.cpp
 *  AgileSpeed
 *
 *  Created by destman on 8/31/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */
#include <time.h>
#include <stdio.h>
#include <cstdarg>
#include <stdlib.h>

#if DEBUG

static FILE * openlog()
{
	const char *workDir=0;
    FILE *rv = 0;
    @autoreleasepool 
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *logDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        workDir = [logDir cStringUsingEncoding:NSASCIIStringEncoding];
        
        time_t rawtime;
        time ( &rawtime );
        struct tm * timeinfo;
        timeinfo = localtime ( &rawtime );	
        
        
        char logPath[65536];
        sprintf(logPath,"%s/%d.%d.%d.log",workDir,1900+timeinfo->tm_year,timeinfo->tm_mon,timeinfo->tm_mday);
        rv = fopen(logPath, "a+");
        if(!rv)
        {
            printf("Error opening log file\n");
        }
    }
    return rv;
}

static void dbg_write(const char *str)
{
    FILE *f_log = openlog();
    if(f_log)
    {
        printf("%lf: %s\n",CFAbsoluteTimeGetCurrent(),str);
        fprintf(f_log,"%lf: %s\n",CFAbsoluteTimeGetCurrent(), str);
        fflush(f_log);
        fclose(f_log);
    }
}

extern void dbgLog(NSString *tmpl, ...)
{
	va_list vl;
	va_start(vl,tmpl);
	NSString *logStr = [[NSString alloc] initWithFormat:tmpl arguments:vl];
	dbg_write([logStr cStringUsingEncoding:NSUTF8StringEncoding]);
    RELEASE(logStr);
	va_end(vl);	
}

void dbg_log(const char *tmpl,...)
{
	va_list vl;
	va_start(vl,tmpl);
	char tmp[65536];
	vsprintf(tmp, tmpl, vl);
	dbg_write(tmp);
	va_end(vl);
}

#endif