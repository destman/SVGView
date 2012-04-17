//
//  SVGGradientInfo.h
//  SVGViewTest
//
//  Created by destman on 8/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "svg.pb.h"
#import "TBXML.h"

bool SVGGradient_ParseLinearGradientFromXML(ProtoSVGElementGradient *gradient,TBXMLElement *element);
bool SVGGradient_ParseRadialGradientFromXML(ProtoSVGElementGradient *gradient,TBXMLElement *element);