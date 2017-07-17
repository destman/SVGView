//
//  SVGPathInfo.h
//  SVGViewTest
//
//  Created by destman on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "svg.pb.h"
#import "TBXML.h"

bool SVGPath_ParseFromXML(ProtoSVGElementPath *path,TBXMLElement *element);
bool SVGPath_ParseEllipseFromXML(ProtoSVGElementPath *path,TBXMLElement *element);
bool SVGPath_ParseCircleFromXML(ProtoSVGElementPath *path,TBXMLElement *element);
bool SVGPath_ParseRectFromXML(ProtoSVGElementPath *path,TBXMLElement *element);
bool SVGPath_ParsePolygonFromXML(ProtoSVGElementPath *path,TBXMLElement *element,bool closePath=true);
bool SVGPath_ParseLineFromXML(ProtoSVGElementPath *path,TBXMLElement *element);


