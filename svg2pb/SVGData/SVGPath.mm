//
//  SVGPathInfo.m
//  SVGViewTest
//
//  Created by destman on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVGPath.h"
#import "SVGGeneralParams.h"
#import "SVGParseTools.h"


static bool parsePathString(ProtoSVGElementPath *path,const char *data)
{
    double  curX=0,curY=0;
    double  prevCurveCDX=0,prevCurveCDY=0;
    BOOL    prevCommandIsCurve = false;
    while(*data)
    {
        bool isAbsolute = true;
        switch (*data) 
        {
            case '\r':
            case '\n':
            case '\t':
            case ' ':
                ++data;
                break;
            case 'm':
                isAbsolute = false;
            case 'M':
            {
                ++data;
                double  vals[2];
                if(!parseNumbers(data,2,vals, &data))
                {
                    dbgLog(@"Error in SVG: expected 2 params: %s",data);
                    return NO;
                }
                if(isAbsolute)
                {
                    curX  = vals[0];
                    curY  = vals[1];
                }else
                {
                    curX += vals[0];
                    curY += vals[1];
                }
                
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->mutable_move_to()->set_x(curX);
                point->mutable_move_to()->set_y(curY);
                prevCommandIsCurve = NO;
                break;
            }
            case 'l':
                isAbsolute = false;
            case 'L':
            {
                ++data;
                double vals[2];
                if(!parseNumbers(data, 2, vals, &data))
                {
                    dbgLog(@"Error in SVG: expected 2 params: %s",data);
                    return NO;
                }
                if(isAbsolute)
                {
                    curX  = vals[0];
                    curY  = vals[1];
                }else
                {
                    curX += vals[0];
                    curY += vals[1];
                }
                
                
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->mutable_line_to()->set_x(curX);
                point->mutable_line_to()->set_y(curY);
                prevCommandIsCurve = NO;
                break;
            }
            case 'h':
                isAbsolute = false;
            case 'H':
            {
                ++data;
                double vals[1];                
                if(!parseNumbers(data, 1, vals, &data))
                {
                    return NO;
                }
                if(isAbsolute)
                {
                    curX = vals[0];
                }else
                {
                    curX += vals[0];
                }
                
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->mutable_line_to()->set_x(curX);
                point->mutable_line_to()->set_y(curY);
                prevCommandIsCurve = NO;
                break;
            }                
            case 'v':
                isAbsolute = false;
            case 'V':
            {
                ++data;
                double vals[1];                
                if(!parseNumbers(data, 1, vals, &data))
                {
                    return NO;
                }
                if(isAbsolute)
                {
                    curY = vals[0];
                }else
                {
                    curY += vals[0];
                }
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->mutable_line_to()->set_x(curX);
                point->mutable_line_to()->set_y(curY);
                prevCommandIsCurve = NO;
                break;
            }
            case 'c':
                isAbsolute = false;
            case 'C':
            {
                ++data;
                double vals[6];
                if(!parseNumbers(data, 6, vals, &data))
                {
                    dbgLog(@"Error in SVG: expected 6 params: %s",data);
                    return NO;
                }
                if(!isAbsolute)
                {
                    for (int i=0; i<3; i++) 
                    {
                        vals[i*2]+=curX;
                        vals[i*2+1]+=curY;
                    }
                }
                curX = vals[4];
                curY = vals[5];
                
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->mutable_curve_to()->set_cp1x(vals[0]);
                point->mutable_curve_to()->set_cp1y(vals[1]);
                point->mutable_curve_to()->set_cp2x(vals[2]);
                point->mutable_curve_to()->set_cp2y(vals[3]);
                point->mutable_curve_to()->set_x(curX);
                point->mutable_curve_to()->set_y(curY);                
                
                prevCurveCDX = vals[2]-curX;
                prevCurveCDY = vals[3]-curY;
                prevCommandIsCurve = YES;
                break;
            }
            case 's':
                isAbsolute = false;
            case 'S':
            {
                ++data;
                double vals[4];
                if(!parseNumbers(data, 4, vals, &data))
                {
                    dbgLog(@"Error in SVG: expected 4 params: %s",data);
                    return NO;
                }
                if(!isAbsolute)
                {
                    for (int i=0; i<2; i++) 
                    {
                        vals[i*2]+=curX;
                        vals[i*2+1]+=curY;
                    }
                }                
                
                if(!prevCommandIsCurve)
                {
                    prevCurveCDX = vals[2]-vals[0];
                    prevCurveCDY = vals[3]-vals[1];
                }
                
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->mutable_curve_to()->set_cp1x(curX-prevCurveCDX);
                point->mutable_curve_to()->set_cp1y(curY-prevCurveCDY);
                point->mutable_curve_to()->set_cp2x(vals[0]);
                point->mutable_curve_to()->set_cp2y(vals[1]);
                point->mutable_curve_to()->set_x(vals[2]);
                point->mutable_curve_to()->set_y(vals[3]);                
                
                curX = vals[2];
                curY = vals[3];
                prevCurveCDX = vals[0]-curX;
                prevCurveCDY = vals[1]-curY;
                prevCommandIsCurve = YES;                
                break;
            }
            
            case 'Z':
            case 'z':
            {
                ++data;
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->set_close_path(true);
                prevCommandIsCurve = NO;
                break;
            }
                
            case 'a':
                isAbsolute = false;
            case 'A': //ARCS not supported
            {
                ++data;
                double vals[7];
                if(!parseNumbers(data, 7, vals, &data))
                {
                    dbgLog(@"Error in SVG: expected 7 params: %s",data);
                    return NO;
                }
                
                if(isAbsolute)
                {
                    curX  = vals[5];
                    curY  = vals[6];
                }else
                {
                    curX += vals[5];
                    curY += vals[6];
                }
                
                ProtoSVGElementPath_PathPoint *point = path->add_points();
                point->mutable_move_to()->set_x(curX);
                point->mutable_move_to()->set_y(curY);
                prevCommandIsCurve = NO;
                dbgLog(@"ARCS not supported");
                break;
            }
            default:
                dbgLog(@"Error in SVG: Unknown path command:%s",data);
                return NO;
        }
    }
    return true;
}


bool SVGPath_ParseFromXML(ProtoSVGElementPath *path,TBXMLElement *element)
{
    __block bool success = SVGGeneralParams_ParseFromXML(path->mutable_params(), element);
    if(SVGGeneralParams_ParseFromXML(path->mutable_params(), element))
    {
        enumAttributes(element, true, ^bool(TBXMLAttribute *attribute) 
                       {
                           dbgLog(@"Warning: unknown attribute %s:%s",attribute->name,attribute->value);
                           return true;
                       },
                       "d",^bool(TBXMLAttribute *attribute) 
                       {
                           if(!parsePathString(path,attribute->value))
                           {
                               success = false;
                           }
                           return true;
                       },
                       NULL);
    }else
    {
        success = false;
    }
    return success;
}

bool SVGPath_ParseEllipseFromXML(ProtoSVGElementPath *path,TBXMLElement *element)
{
    __block bool success = SVGGeneralParams_ParseFromXML(path->mutable_params(), element);
    enumAttributes(element, true, ^bool(TBXMLAttribute *attribute) 
                   {
                       dbgLog(@"Warning: unknown attribute %s:%s",attribute->name,attribute->value);
                       return true;
                   },
                   "cx",^bool(TBXMLAttribute *attribute) 
                   {
                       path->set_cx(atof(attribute->value));
                       return true;
                   },
                   "cy",^bool(TBXMLAttribute *attribute) 
                   {
                       path->set_cy(atof(attribute->value));
                       return true;
                   },
                   "rx",^bool(TBXMLAttribute *attribute) 
                   {
                       path->set_rx(atof(attribute->value));
                       return true;
                   },
                   "ry",^bool(TBXMLAttribute *attribute) 
                   {
                       path->set_ry(atof(attribute->value));
                       return true;
                   },
                   NULL);
    return success;
}

bool SVGPath_ParseCircleFromXML(ProtoSVGElementPath *path,TBXMLElement *element)
{
    __block bool success = SVGGeneralParams_ParseFromXML(path->mutable_params(), element);
    enumAttributes(element, true, ^bool(TBXMLAttribute *attribute) 
                   {
                       dbgLog(@"Warning: unknown attribute %s:%s",attribute->name,attribute->value);
                       return true;
                   },
                   "cx",^bool(TBXMLAttribute *attribute) 
                   {
                       path->set_cx(atof(attribute->value));
                       return true;
                   },
                   "cy",^bool(TBXMLAttribute *attribute) 
                   {
                       path->set_cy(atof(attribute->value));
                       return true;
                   },
                   "r",^bool(TBXMLAttribute *attribute) 
                   {
                       path->set_r(atof(attribute->value));
                       return true;
                   },
                   NULL);
    return success;    
}

bool SVGPath_ParseRectFromXML(ProtoSVGElementPath *path,TBXMLElement *element)
{
    __block bool success = SVGGeneralParams_ParseFromXML(path->mutable_params(), element);
    enumAttributes(element, true, ^bool(TBXMLAttribute *attribute) 
                   {
                       dbgLog(@"Warning: unknown attribute %s:%s",attribute->name,attribute->value);
                       return true;
                   },
                   "x",^bool(TBXMLAttribute *attribute) 
                   {
                       path->mutable_rect()->set_x(atof(attribute->value));
                       return true;
                   },
                   "y",^bool(TBXMLAttribute *attribute) 
                   {
                       path->mutable_rect()->set_y(atof(attribute->value));
                       return true;
                   },
                   "width",^bool(TBXMLAttribute *attribute) 
                   {
                       path->mutable_rect()->set_w(atof(attribute->value));
                       return true;
                   },
                   "height",^bool(TBXMLAttribute *attribute) 
                   {
                       path->mutable_rect()->set_h(atof(attribute->value));
                       return true;
                   },
                   NULL);
    return success;
}


static bool parsePolygonPoints(ProtoSVGElementPath *path,const char *data,bool closePath)
{
    double point[2];
    while (parseNumbersFromRow(data, 2, point, &data)) 
    {
        ProtoSVGElementPath_PathPoint *nextPoint = path->add_points();
        if(path->points_size()==1)
        {
            nextPoint->mutable_move_to()->set_x(point[0]);
            nextPoint->mutable_move_to()->set_y(point[1]);            
        }else
        {
            nextPoint->mutable_line_to()->set_x(point[0]);
            nextPoint->mutable_line_to()->set_y(point[1]);            
        }
    }
    if(closePath)
    {
        ProtoSVGElementPath_PathPoint *nextPoint = path->add_points();
        nextPoint->set_close_path(true);
        return path->points_size()>=3;
    }
    return path->points_size()>=2;
}

bool SVGPath_ParseLineFromXML(ProtoSVGElementPath *path,TBXMLElement *element)
{
    __block bool success = SVGGeneralParams_ParseFromXML(path->mutable_params(), element);
    
    __block double x1, y1, x2, y2;
    
    enumAttributes(element, true, ^bool(TBXMLAttribute *attribute)
                   {
                       dbgLog(@"Warning: unknown attribute %s:%s",attribute->name,attribute->value);
                       return true;
                   },
                   "x1",^bool(TBXMLAttribute *attribute)
                   {
                       char *nextVal = NULL;
                       x1 = strtod(attribute->value, &nextVal);
                       if( nextVal == attribute->value )
                       {
                           success = false;
                       }
                       return true;
                   },
                   "y1",^bool(TBXMLAttribute *attribute)
                   {
                       char *nextVal = NULL;
                       y1 = strtod(attribute->value, &nextVal);
                       if( nextVal == attribute->value )
                       {
                           success = false;
                       }
                       return true;
                   },
                   "x2",^bool(TBXMLAttribute *attribute)
                   {
                       char *nextVal = NULL;
                       x2 = strtod(attribute->value, &nextVal);
                       if( nextVal == attribute->value )
                       {
                           success = false;
                       }
                       return true;
                   },
                   "y2",^bool(TBXMLAttribute *attribute)
                   {
                       char *nextVal = NULL;
                       y2 = strtod(attribute->value, &nextVal);
                       if( nextVal == attribute->value )
                       {
                           success = false;
                       }
                       return true;
                   },
                   NULL);
    
    if (success) {
        ProtoSVGElementPath_PathPoint *pt = path->add_points();
        pt->mutable_move_to()->set_x(x1);
        pt->mutable_move_to()->set_y(y1);
        
        pt = path->add_points();
        pt->mutable_line_to()->set_x(x2);
        pt->mutable_line_to()->set_y(y2);
    }
    
    return success;
}

bool SVGPath_ParsePolygonFromXML(ProtoSVGElementPath *path,TBXMLElement *element, bool closePath)
{
    __block bool success = SVGGeneralParams_ParseFromXML(path->mutable_params(), element);

    enumAttributes(element, true, ^bool(TBXMLAttribute *attribute) 
                   {
                       dbgLog(@"Warning: unknown attribute %s:%s",attribute->name,attribute->value);
                       return true;
                   },
                   "points",^bool(TBXMLAttribute *attribute) 
                   {
                       if(!parsePolygonPoints(path,attribute->value,closePath))
                       {
                           success = false;
                       }
                       return true;
                   },
                   NULL);
    return success;
}
