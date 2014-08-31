//
//  SVGData.m
//  SVGViewTest
//
//  Created by destman on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVGRoot.h"
#import "SVGParseTools.h"
#import "SVGGeneralParams.h"
#import "SVGGradient.h"
#import "SVGPath.h"

bool SVGRoot_ParseChilds(TBXMLElement *element, ProtoSVGGeneralParams *params)
{
    enumElements(element, ^void(TBXMLElement *element) 
                 {
                     dbgLog(@"Warning while loading svg: unknown tag %s",element->name);
                 },
                 "defs",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(SVGGeneralParams_ParseFromXML(newChild->mutable_defs(), element))
                     {
                         SVGRoot_ParseChilds(element->firstChild, newChild->mutable_defs());
                     }else
                     {
                         params->mutable_childs()->RemoveLast();
                     }
                 },                 
                 "g",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(SVGGeneralParams_ParseFromXML(newChild->mutable_group(), element))
                     {
                         SVGRoot_ParseChilds(element->firstChild, newChild->mutable_group());
                     }else
                     {
                         params->mutable_childs()->RemoveLast();
                     }
                 },                   
                 "path",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGPath_ParseFromXML(newChild->mutable_path(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }else
                     {
                         ++nPathElements;
                     }
                 },
                 "ellipse",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGPath_ParseEllipseFromXML(newChild->mutable_path(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }                     
                 },
                 "circle",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGPath_ParseCircleFromXML(newChild->mutable_path(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }                     
                 },
                 "rect",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGPath_ParseRectFromXML(newChild->mutable_path(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }                      
                 },
                 "polygon",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGPath_ParsePolygonFromXML(newChild->mutable_path(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }                      
                 },
                 "line",^void(TBXMLElement *element)
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGPath_ParseLineFromXML(newChild->mutable_path(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }
                 },
                 "polyline",^void(TBXMLElement *element) 
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGPath_ParsePolygonFromXML(newChild->mutable_path(), element,false))
                     {
                         params->mutable_childs()->RemoveLast();
                     }                      
                 },                  
                 "linearGradient",^void(TBXMLElement *element)
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGGradient_ParseLinearGradientFromXML(newChild->mutable_gradient(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }                      
                 },
                 "radialGradient",^void(TBXMLElement *element)
                 {
                     ProtoSVGElement *newChild = params->add_childs();
                     if(!SVGGradient_ParseRadialGradientFromXML(newChild->mutable_gradient(), element))
                     {
                         params->mutable_childs()->RemoveLast();
                     }                      
                 },                 
                 0);    
    return true;
};


ProtoSVGRoot *SVGRoot_ParseFromXML(TBXMLElement *element)
{
    ProtoSVGRoot *rv = nil;
    
    if([[TBXML elementName:element] isEqualToString:@"svg"])
    {
        rv = new ProtoSVGRoot();
        if(SVGGeneralParams_ParseFromXML(rv->mutable_params(),element))
        {
            rv->mutable_frame()->set_w(1);
            rv->mutable_frame()->set_h(1);
            
            enumAttributes(element, true, nil,
                           "width",^bool(TBXMLAttribute *attribute) 
                           {
                               rv->mutable_frame()->set_w(atof(attribute->value));
                               return true;
                           },
                           "height",^bool(TBXMLAttribute *attribute) 
                           {
                               rv->mutable_frame()->set_h(atof(attribute->value));
                               return true;
                           },
                           "x",^bool(TBXMLAttribute *attribute) 
                           {
                               rv->mutable_frame()->set_x(atof(attribute->value));
                               return true;
                           },
                           "y",^bool(TBXMLAttribute *attribute) 
                           {
                               rv->mutable_frame()->set_y(atof(attribute->value));
                               return true;
                           },                           
                           
                           "viewBox",^bool(TBXMLAttribute *attribute) 
                           {
                               double vals[4];
                               const char *end;
                               if(parseNumbers(attribute->value, 4, vals, &end))
                               {
                                   rv->mutable_bounds()->set_x(vals[0]);
                                   rv->mutable_bounds()->set_y(vals[1]);
                                   rv->mutable_bounds()->set_w(vals[2]);
                                   rv->mutable_bounds()->set_h(vals[3]);
                               }else
                               {
                                   dbgLog(@"Error in loadin svg:invalid viewBox %s",attribute->value);
                                   return false;
                               }                               
                               return true;
                           },                       
                           0);            
            
            if(!rv->has_bounds())
            {
                rv->mutable_bounds()->CopyFrom(rv->frame());
            }
            
            if(!SVGRoot_ParseChilds(element->firstChild, rv->mutable_params()))
            {
                delete rv;
                rv = 0;
            }
        }else
        {
            delete rv;
            rv = 0;
        }
        
        
        
    }
    return rv;
}


/*@implementation SVGData

- (void) dealloc
{
    [super dealloc];
}

- (void) expandIDLinks:(SVGBaseObject *)curObject
{
    if([curObject.fillValue isKindOfClass:[NSString class]])
    {
        NSString *linkObjectID = curObject.fillValue;
        SVGBaseObject *linkObject = [self findObjectWithID:linkObjectID];
        if(linkObject==nil)
        {
            dbgLog(@"Failed to find object with id %@",linkObjectID);
        }
        curObject.fillValue = linkObject;
    }
    
    for (SVGBaseObject *nextObject in curObject)
    {
        [self expandIDLinks:nextObject];
    }
}

- (void) applyTransfromForSize:(CGSize)size toContext:(CGContextRef)context
{
    CGContextTranslateCTM   (context, _frame.origin.x               , _frame.origin.y);
    double sx = size.width/_frame.size.width;
    double sy = size.height/_frame.size.height;
    
    if(sx>sy)
    {
        sx=sy;
    }else
    {
        sy=sx;
    }
    CGContextScaleCTM(context, sx, sy );
    
    CGContextTranslateCTM(context, -_bounds.origin.x, -_bounds.origin.y);
    CGContextScaleCTM(context, _frame.size.width/_bounds.size.width, _frame.size.height/_bounds.size.height);
    
}

@end*/
