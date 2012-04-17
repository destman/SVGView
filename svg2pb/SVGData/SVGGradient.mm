//
//  SVGGradientInfo.m
//  SVGViewTest
//
//  Created by destman on 8/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVGGradient.h"
#include "SVGGeneralParams.h"
#include "SVGParseTools.h"


bool parseStyleString(const char *str, ProtoSVGElementGradient_GradientStop *stop)
{
    while (str) 
    {
        char *nextPart = strstr(str, ";");
        
        char *curPart = nil;
        int curLen = nextPart-str;
        if(nextPart)
        {
            curLen = nextPart-str;
        }else
        {
            curLen = strlen(str);
        }
        curPart = (char *)malloc(curLen+1);
        memcpy(curPart, str, curLen);
        curPart[curLen] = 0;
        
        if(strncmp("stop-color:", curPart, 11)==0)
        {
            if(!parseColorString(stop->mutable_color(), curPart+11))
            {
                return false;
            }
        }else if(strncmp("stop-opacity:", curPart, 13)==0)
        {
            stop->set_alpha(atof(curPart+13));
        }else
        {
            return false;
        }             
        if(nextPart)
        {
            str = nextPart+1;
        }else
        {
            str = nil;
        }
        free(curPart);
    }
    
    return true;
}


bool parseGradientSteps(ProtoSVGElementGradient *gradient,TBXMLElement *element)
{
    __block bool success = true;
    TBXMLElement *child = element->firstChild;
    while (child) 
    {
        NSString *childName = [TBXML elementName:child];
        if([childName isEqualToString:@"stop"])
        {
            __block ProtoSVGElementGradient_GradientStop *stop = gradient->add_stops();
            enumAttributes(child, true, ^bool(TBXMLAttribute *attribute) 
                           {
                               dbgLog(@"Warning : uknown param in gradient stop %@",attribute->name);
                               return true;
                           },
                           "offset", ^bool(TBXMLAttribute *attribute) 
                           {
                               stop->set_offset(atof(attribute->value));
                               return true;
                           },
                           "style",^bool(TBXMLAttribute *attribute) 
                           {
                               if(!parseStyleString(attribute->value,stop))
                               {
                                   dbgLog(@"Error in gradient style unknown: %s",attribute->value);
                                   success = false;
                               }
                               return true;
                           },
                           0);
        }else
        {
            dbgLog(@"Warning : uknown data in gradient %@",childName);
        }
        child = child->nextSibling;
    }    
    return success;

}


bool SVGGradient_ParseLinearGradientFromXML(ProtoSVGElementGradient *gradient,TBXMLElement *element)
{
    __block bool success = SVGGeneralParams_ParseFromXML(gradient->mutable_params(), element);
    enumAttributes(element, true, ^bool(TBXMLAttribute *attribute) 
                   {
                       dbgLog(@"Error loading svg: Unknown attribute %s in gradient",attribute->name);            
                       success = false;
                       return false;
                   },
                   "gradientUnits",^bool(TBXMLAttribute *attribute)
                   {
                       if(strcmp(attribute->value, "userSpaceOnUse"))
                       {
                           success = false;
                           dbgLog(@"Unknown gradient gradientUnits %s",attribute->value);
                       }
                       return true;
                   },
                   "x1",^bool(TBXMLAttribute *attribute) 
                   {
                       gradient->mutable_startpoint()->set_x(atof(attribute->value));
                       return true;
                   },
                   "y1",^bool(TBXMLAttribute *attribute) 
                   {
                       gradient->mutable_startpoint()->set_y(atof(attribute->value));
                       return true;
                   },
                   "x2",^bool(TBXMLAttribute *attribute) 
                   {
                       gradient->mutable_endpoint()->set_x(atof(attribute->value));
                       return true;
                   },
                   "y2",^bool(TBXMLAttribute *attribute) 
                   {
                       gradient->mutable_endpoint()->set_y(atof(attribute->value));
                       return true;
                   },
                   "gradientTransform",^bool(TBXMLAttribute *attribute) 
                   {
                       if(!parseMatrixString(gradient->mutable_gradienttransform(), attribute->value))
                       {
                           success = false;
                           return false;
                       }                           
                       return true;
                   },
                   0);    
    
    
    if(success)
    {
        success = parseGradientSteps(gradient, element);
    }    
    return success;    
}

bool SVGGradient_ParseRadialGradientFromXML(ProtoSVGElementGradient *gradient,TBXMLElement *element)
{
    __block bool success = SVGGeneralParams_ParseFromXML(gradient->mutable_params(), element);
    enumAttributes(element, true, ^bool(TBXMLAttribute *attribute) 
                   {
                       dbgLog(@"Error loading svg: Unknown attribute %s in gradient",attribute->name);            
                       //success = false;
                       return true;
                   },
                   "gradientUnits",^bool(TBXMLAttribute *attribute)
                   {
                       if(strcmp(attribute->value, "userSpaceOnUse"))
                       {
                           success = false;
                           dbgLog(@"Unknown gradient gradientUnits %s",attribute->value);
                       }
                       return true;
                   },
                   "cx",^bool(TBXMLAttribute *attribute) 
                   {
                       gradient->mutable_center()->set_x(atof(attribute->value));
                       return true;
                   },
                   "cy",^bool(TBXMLAttribute *attribute) 
                   {
                       gradient->mutable_center()->set_y(atof(attribute->value));
                       return true;
                   },
                   "r",^bool(TBXMLAttribute *attribute) 
                   {
                       gradient->set_r(atof(attribute->value));
                       return true;
                   },
                   "gradientTransform",^bool(TBXMLAttribute *attribute) 
                   {
                       if(!parseMatrixString(gradient->mutable_gradienttransform(), attribute->value))
                       {
                           success = false;
                           return false;
                       }                           
                       return true;
                   },
                   0);    
    
    
    if(success)
    {
        success = parseGradientSteps(gradient, element);
    }    
    return success;    
}


