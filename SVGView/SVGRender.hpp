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

/*!
    Struct used to simplify integration with pure Obj-C code
 */
struct SVGRender
{
private:
    struct SVGRenderPrivate *_private;
public:
    SVGRender();
    ~SVGRender();
    
    /*!
     Close file and clear all cached data
     */
    void close();
    
    /*!
     Open SVG file. Name is full path to file
     */
    bool openFile(const char *name);
    
    /*!
     Open SVG from raw data
     */
    bool open(const void *data, uint32_t dataSize);
    
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
    
    std::set<int>  statesAtPoint(CGPoint point, CGSize size, bool activeOnly=true);

    CGRect getRect();
};

#endif
