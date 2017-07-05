//
//  main.cpp
//  svg2pb
//
//  Created by Arkadiy Tolkun on 13.09.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "svg.pb.h"
#include "PBFileStream.h"
#include "TBXML.h"
#include "SVGRoot.h"
#include "SVGPath.h"

static void printPathPoints(int level,const ProtoSVGElementPath *path)
{
    for(int i=0;i<path->points_size();i++)
    {
        const ProtoSVGElementPath_PathPoint *point = &path->points(i);
        for (int i=0;i<level;i++)
        {
            printf(" ");
        }
        printf("Point %d size=%d\n", i, point->ByteSize());
    }
}

static void printStructure(int level,const ProtoSVGGeneralParams *params)
{
    for(int i=0;i<params->childs_size();i++)
    {
        const ProtoSVGElement *element = &params->childs(i);
        for (int i=0;i<level;i++)
        {
            printf(" ");
        }
        
        printf("Child %d size = %d",i, element->ByteSize());
        if(element->has_group())
        {
            printf("(group)\n");
            printStructure(level+1,&element->group());
        }else if(element->has_path())
        {
            printf("(path %d points)\n",element->path().points_size());
            printPathPoints(level+1, &element->path());
        }else
        {
            printf("(unknown)\n");
        }
    }
}

int main (int argc, const char * argv[])
{
    dbg_log("svg2pb v1.1\n");
    
    if(argc!=3)
    {
        printf("Usage:\n");
        printf("svg2pb input.svg output.svgpb\n");
        return 1;
    }
    
    dbg_log("Input file= %s\n",argv[1]);
    dbg_log("Output file= %s\n",argv[2]);
    
    PBFileOutputStream stream;
    if(stream.open(argv[2])) 
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        dbg_log("Opening XML");
        TBXML *xml = [[TBXML alloc] initWithURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
        if(!xml || !xml.rootXMLElement)
        {
            printf("Failed to open svg file %s\n", argv[1]);
            return 2;
        }

        nPathElements = 0;
       
        nPathPoints_Move=0;
        nPathPoints_Line=0;
        nPathPoints_HLine=0;
        nPathPoints_VLine=0;
        nPathPoints_Curve=0;
        nPathPoints_ShortCurve=0;
        nPathPoints_ColosePath=0;        
        
        dbg_log("Parsing XML");
        ProtoSVGRoot *svg=0;
        @try 
        {
            try 
            {
                svg = SVGRoot_ParseFromXML(xml.rootXMLElement);
            } catch (...) 
            {
                dbg_log("Crash in parse");
            }
        }
        @catch (NSException *exception) 
        {
            dbg_log("Crash in parse");
        }
        //optimizeSVG(svg->mutable_params());
        [pool release];
        if(!svg)
        {
            printf("Failed to parse svg\n");
            return 3;
        }
        
        int outSize = svg->ByteSize();
        //printStructure(0,&svg->params());
        dbg_log("Output size = %d",outSize);
        dbg_log("Path elements = %d",nPathElements);
        dbg_log("Total path points = %d",nPathPoints_Move+nPathPoints_Line+nPathPoints_HLine+nPathPoints_VLine+nPathPoints_Curve+nPathPoints_ShortCurve+nPathPoints_ColosePath);
        dbg_log("Move points = %d"  ,nPathPoints_Move);
        dbg_log("Line points = %d"  ,nPathPoints_Line);
        dbg_log("HLine points = %d" ,nPathPoints_HLine);
        dbg_log("VLine points = %d" ,nPathPoints_VLine);
        dbg_log("Curve points = %d" ,nPathPoints_Curve);
        dbg_log("SCurve points = %d",nPathPoints_ShortCurve);
        dbg_log("Close points = %d" ,nPathPoints_ColosePath);
        
        dbg_log("Saving svgpb");
        if(!svg->SerializeToZeroCopyStream(&stream))
        {
            printf("Failed to save pb file\n");
            return 4;
        }
    }else
    {
        printf("Failed to open output file %s\n",argv[2]);
        return 5;
    }
    
    return 0;
}

