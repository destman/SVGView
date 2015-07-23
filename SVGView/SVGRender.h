//
//  SVGRender.h
//  SVGViewTest
//
//  Created by Arkadiy Tolkun on 31.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef SVGRender_h
#define SVGRender_h

#include <map>
#include <set>
#include <vector>
using namespace std;

#import "svg.pb.h"
#import "PBFileStream.h"

/*! Block used for enumerating objects
 *  @param object - next object in enumeration
 *  @returns return true to continue enum.
 */
typedef bool (^SVGRenderEnumBlock)(const ProtoSVGElement *object);

/*!
    Struct used to simplify integration with pure Obj-C code
 */
struct SVGRender
{
private:
    struct RenderContext {
        ProtoSVGPaint fill;
    };
    
    ProtoSVGRoot _root;
    map<const ProtoSVGElementPath*, CGPathRef>              _pathMap;
    map<const ProtoSVGElementGradient*, CGGradientRef>      _gradientMap;
    set<int>                                                _activeStates;
    set<int>                                                _allStates;
    
    CGColorSpaceRef _colorSpace;

    //return true if need to restore state
    bool prepareToDraw(CGContextRef context,const ProtoSVGGeneralParams *object);
    
    CGPathRef buildCGPath(const ProtoSVGElementPath *path);
    CGPathRef getCGPathForPath(const ProtoSVGElementPath *path);
    CGGradientRef buildCGGradient(const ProtoSVGElementGradient *gradient);
    CGGradientRef getCGGradientForGradient(const ProtoSVGElementGradient *gradient);
    const ProtoSVGElement *findElementById(const string &name);
    void drawPath(CGContextRef context,const ProtoSVGElementPath *pathObject, RenderContext &rc);
    
    
    CGAffineTransform transformForSize(CGSize size);
    bool isGroupActive(const ProtoSVGGeneralParams *group);

    
    bool renderElements(SVGRenderEnumBlock renderEnterBlock, SVGRenderEnumBlock renderExitBlock, const ProtoSVGElement *object, bool onlyActive);
    void renderElements(SVGRenderEnumBlock renderEnterBlock, SVGRenderEnumBlock renderExitBlock, bool onlyActive=true);

    static set<int> statesFromName(const string &name);
public:
    SVGRender();
    ~SVGRender();
    
    /*!
     Close file and clear all cached data
     */
    void closeFile();
    
    /*!
     Open file. Name is full path to file
     */
    bool openFile(const char *name);
    
    /*!
     Call this to prepare draw. Cacehs data needed to draw.
     */
    void prepareToDrawData();
    
    /*!
     Draw svg at given context with given size
     */
    void draw(CGContextRef context, CGSize size,  bool clearContext=true);
    
    /*!
     Create UIImage with specified state and scale. It is safe to call this function from any thread.
     No function that require main thread is called.
     */
    UIImage *createUIImage(CGSize size, double scale);
    
    /*
     Check if file have state with given number. (state - this is group of svg elements with name like <some name>-state-<state number>)
     */
    bool haveState(int stateNm);
    
    bool isStateActive(int stateNm);
    void setStateActive(int stateNm);
    void setStateInactive(int stateNm);
    void setAllStatesInactive();
    
    /*
     Check if any path contain specified point
     */
    bool isPointInside(CGPoint point, CGSize size);
    
    set<int>  statesAtPoint(CGPoint point, CGSize size, bool activeOnly=true);

    CGRect getRect();
};

#endif
