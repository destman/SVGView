//
//  SVGParseTools.m
//  SVGViewTest
//
//  Created by destman on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SVGParseTools.h"
#import <map>
#import <string>
using namespace std;


bool parseNumbersFromRow(const char *data, int count, double *result, const char **lastChar)
{
    char *nextNumber = NULL;
    while (count>0) 
    {
        *result = strtod(data, &nextNumber);
        if(nextNumber==data) break;
        if(nextNumber==0) break;        
        if(*nextNumber==',')
        {
            ++nextNumber;
        }        
        
        result++;
        data = nextNumber;
        count--;
    }
    if(lastChar)
        *lastChar = data;    
    return count==0;
}

bool parseNumbers(const char *data,int expectedNumbersCount, double *result, const char **lastChar)
{
    bool haveMinNumbers = parseNumbersFromRow(data, expectedNumbersCount, result, lastChar);
    if(!haveMinNumbers)
    {
        dbgLog(@"Error in SVG: expected %d params: %s",expectedNumbersCount,data);  
        return false;
    }
    
    double temp;
    bool haveMoreNumbers = parseNumbersFromRow(*lastChar, 1, &temp, 0);
    if (haveMoreNumbers) 
    {
        dbgLog(@"Error in SVG: expected %d params: %s",expectedNumbersCount,data);  
        return false;
    }
    return true;
}

bool    parseMatrixString(ProtoAffineTransformMatrix *matrix, const char *data)
{
    if(strncmp("matrix(", data, 7)==0)
    {
        double vals[6];
        if(parseNumbers(data+7, 6, vals, &data))
        {
            matrix->set_a (vals[0]);
            matrix->set_b (vals[1]);
            matrix->set_c (vals[2]);
            matrix->set_d (vals[3]);
            matrix->set_tx(vals[4]);
            matrix->set_ty(vals[5]);
            return true;
        }
    }else if(strncmp("translate(", data, 10)==0)
    {
        double vals[2];
        if(parseNumbers(data+10, 2, vals, &data))
        {
            matrix->set_tx(vals[0]);
            matrix->set_ty(vals[1]);
            return true;
        }
    }else
    {
        dbgLog(@"Error loading svg: Transfrom not supported %s",data);
    }
    return false;
}

void enumElements(TBXMLElement *element,EnumElementsBlock unknownElementBlock,...)
{
    map<string,EnumElementsBlock> searchMap;
    {
        va_list vl;
        va_start(vl,unknownElementBlock);
        while (true)
        {
            const char *nextName = va_arg(vl, const char *);
            if (!nextName)
                break;
            
            EnumElementsBlock attribBlock = (EnumElementsBlock)va_arg(vl, void *);
            if (!attribBlock)
                break;
            
            searchMap.insert(std::pair<string, EnumElementsBlock>(nextName,attribBlock));
        }
        va_end(vl);
    }        
    
    while (element) 
    {
        EnumElementsBlock block = nil;
        map<string, EnumElementsBlock>::iterator it = searchMap.find(element->name);
        if(it!=searchMap.end())
        {
            block = it->second;
        }            
        if(block)
        {
            block(element);
        }else
        {
            unknownElementBlock(element);
        }
        element = element->nextSibling;
    }
}


void enumAttributes(TBXMLElement *element,bool removeOnSuccess,EnumAttributesBlock unknownAttributeBlock,...)
{
    map<string,EnumAttributesBlock> attribMap;
    {
        va_list vl;
        va_start(vl,unknownAttributeBlock);
        while (true)
        {
            const char *nextName = va_arg(vl, const char *);
            if (!nextName)
                break;
            
            EnumAttributesBlock attribBlock = (EnumAttributesBlock)va_arg(vl, void *);
            if (!attribBlock)
                break;
            
            attribMap.insert(std::pair<string, EnumAttributesBlock>(nextName,attribBlock));
        }            
        va_end(vl);
    }
    
    TBXMLAttribute *attribure = element->firstAttribute;
    TBXMLAttribute *prevAttribute = 0;
    while (attribure) 
    {
        EnumAttributesBlock block = nil;
        map<string, EnumAttributesBlock>::iterator it = attribMap.find(attribure->name);
        if(it!=attribMap.end())
        {
            block = it->second;
        }
        bool continueSearch=true;
        if(block)
        {
            continueSearch = block(attribure);
            if(removeOnSuccess)
            {
                if(prevAttribute==nil)
                {
                    element->firstAttribute = attribure->next;
                }else
                {
                    prevAttribute->next = attribure->next;
                }
            }
        }else
        {
            if(unknownAttributeBlock)
            {
                continueSearch = unknownAttributeBlock(attribure);
            }
            prevAttribute = attribure;
        }
        if(!continueSearch)
            break;
        attribure = attribure->next;
    }
}

bool parseColorString(ProtoColor *color, const char *val)
{
    int len = strlen(val);
    if(*val=='#' && len==7)
    {
        long l = strtol(val+1, nil, 16);
        unsigned char *bgr = (unsigned char *)&l;
        color->set_r(bgr[2]);
        color->set_g(bgr[1]);
        color->set_b(bgr[0]);
        return true;
    }else if(*val=='#' && len==4)
    {
        long l = strtol(val+1, nil, 16);
        color->set_r(( (l >> 8) & 0xf ) * 0x11);
        color->set_g(( (l >> 4) & 0xf ) * 0x11);
        color->set_b(( l & 0xf ) * 0x11);
        return true;
    }
    return false;
}



bool parsePaintString(ProtoSVGPaint *paint, const char *val)
{
    int len = strlen(val);
    if(parseColorString(paint->mutable_color(), val))
    {
        return true;
    }else 
    {
        paint->clear_color();
        if(len>6 && strncmp("url(#", val, 5)==0)
        {
            if(val[len-1]==')')
            {
                paint->set_ref_id(val+5, len-6);
                return true;
            }
        }else if(len==4 && strncmp("none", val, 4)==0)
        {
            paint->set_paint_off(true);
            return true;
        }
    }
    dbgLog(@"Error in svg: Invalid paint %s",val);
    return false;
}    


