//
//  SVGBaseObject.m
//  SVGViewTest
//
//  Created by destman on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


#import "SVGGeneralParams.h"
#import "SVGParseTools.h"

bool SVGGeneralParams_ParseFromXML(ProtoSVGGeneralParams *params, TBXMLElement *element)
{
    __block bool success = true;
    enumAttributes(element, true, 0,
                   "id",^bool(TBXMLAttribute *attribute) 
                   {
                       params->set_id(attribute->value);
                       return true;
                   },
                   "fill",^bool(TBXMLAttribute *attribute) 
                   {
                       if(!parsePaintString(params->mutable_fill(),attribute->value))
                       {
                           params->clear_fill();
                       }
                       return true;
                   },
                   "fill-opacity",^bool(TBXMLAttribute *attribute)
                   {
                       params->set_opacity(atof(attribute->value));
                       return true;
                   },
                   "stroke",^bool(TBXMLAttribute *attribute) 
                   {
                       if(!parsePaintString(params->mutable_stroke(),attribute->value))
                       {
                           params->clear_stroke();
                       }
                       return true;
                   },
                   "stroke-width",^bool(TBXMLAttribute *attribute)
                   {
                       params->mutable_stroke()->set_stroke_width(atof(attribute->value));
                       return true;
                   },
                   "fill-rule",^bool(TBXMLAttribute *attribute) 
                   {
                       if([[TBXML attributeValue:attribute] isEqualToString:@"evenodd"])
                       {
                           params->mutable_fill()->set_odd(true);
                       }else
                       {
                           dbgLog(@"Unknown fill rule %s",attribute->value);
                       }
                       return true;
                   },
                   "clip-rule",^bool(TBXMLAttribute *attribute) 
                   {
                       //ignore it
                       return true;
                   },                   
                   "opacity",^bool(TBXMLAttribute *attribute) 
                   {
                       params->set_opacity(atof(attribute->value));
                       return true;
                   },                      
                   "transform",^bool(TBXMLAttribute *attribute) 
                   {
                       if(!parseMatrixString(params->mutable_transform(),attribute->value))
                       {
                           params->clear_transform();
                           success = false;
                           return false;
                       }
                       return true;
                   },
                   "display",^bool(TBXMLAttribute *attribute)
                   {
                       //params->set_display(attribute->value);
                       if ([[TBXML attributeValue:attribute] isEqualToString:@"none"]) {
                           success = false;
                           return false;
                       }
                       
                       return true;
                   }, NULL);
    return success;
}
