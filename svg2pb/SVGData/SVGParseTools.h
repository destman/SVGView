//
//  SVGParseTools.h
//  SVGViewTest
//
//  Created by destman on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TBXML.h"
#import "svg.pb.h"

typedef bool(^EnumAttributesBlock)(TBXMLAttribute *attribute);
typedef void(^EnumElementsBlock)(TBXMLElement *element);

void enumAttributes(TBXMLElement *element,bool removeOnSuccess,EnumAttributesBlock unknownAttributeBlock,...);
void enumElements(TBXMLElement *element,EnumElementsBlock unknownElementBlock,...);

bool parseNumbers(const char *data,int expectedNumbersCount, double *result, const char **lastChar);
bool parseNumbersFromRow(const char *data, int count, double *result, const char **lastChar);
bool parseMatrixString(ProtoAffineTransformMatrix *matrix, const char *data);
bool parsePaintString(ProtoSVGPaint *paint, const char *val);
bool parseColorString(ProtoColor    *color, const char *val);
