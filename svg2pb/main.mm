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

static void enumPath(const ProtoSVGGeneralParams &params, const std::function<void(const ProtoSVGElementPath &path)> &callback)
{
    for(auto &child : params.childs())
    {
        if(child.has_group())
            enumPath(child.group(), callback);
        if(child.has_defs())
            enumPath(child.defs(), callback);
        if(child.has_path())
            callback(child.path());
    }    
}

static void printGeomStats(ProtoSVGRoot *svg)
{
    int nPathElements = 0;
    int nPathPoints_Move = 0;
    int nPathPoints_Line = 0;
    int nPathPoints_Curve = 0;
    int nPathPoints_ColosePath = 0;
    
    enumPath(svg->params() , [&](const ProtoSVGElementPath&path){
        nPathElements++;
        for(auto &point : path.points())
        {
            if(point.has_move_to())
                nPathPoints_Move++;
            if(point.has_line_to())
                nPathPoints_Line++;
            if(point.has_curve_to())
                nPathPoints_Curve++;
            if(point.has_close_path())
                nPathPoints_ColosePath++;
        }
    });
    dbg_log("Path elements = %d",nPathElements);
    dbg_log("Total path points = %d",nPathPoints_Move+nPathPoints_Line+nPathPoints_Curve+nPathPoints_ColosePath);
    dbg_log("Move points = %d"  ,nPathPoints_Move);
    dbg_log("Line points = %d"  ,nPathPoints_Line);
    dbg_log("Curve points = %d" ,nPathPoints_Curve);
    dbg_log("Close points = %d" ,nPathPoints_ColosePath);
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
        
#ifdef DEBUG
        //printStructure(0,&svg->params());
        dbg_log("Output size = %d", svg->ByteSize());
        printGeomStats(svg);
#endif
        
        
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

