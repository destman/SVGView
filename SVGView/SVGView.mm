//
//  SVGView.m
//  SVGView
//
//  Created by destman on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVGView.h"
#import <QuartzCore/QuartzCore.h>

#include "SVGRender.hpp"

@implementation SVGView

- (void) _init
{
    _render = new SVGRender();
    self.layer.shouldRasterize = YES;
}

- (id) initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        [self _init];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
    {
        [self _init];
    }
    return self;
}

- (id)  init
{
    return [self initWithFrame:CGRectZero];
}

- (void) dealloc
{
    if (_render) 
    {
        delete _render;
        _render = nil;
    }
#if !HAVE_ARC
    [_svgFile release];
    [super dealloc];
#endif
}

- (void) drawRect:(CGRect)rect
{
    NSLog(@"SVGView: draw request");
    @synchronized(self)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        _render->draw(context,self.bounds.size);
    }
    NSLog(@"SVGView: draw request finished");
}

- (void) prepareToDraw
{
    @synchronized(self)
    {
        _render->prepareToDrawData();
    }
}


+ (UIImage *) imageWithSize:(CGSize) size fromSVGFile:(NSString *)fullFileName;
{
    UIImage *rv = nil;
    SVGRender *data = new SVGRender();
    if(data->openFile([fullFileName UTF8String]))
    {
        rv = data->createUIImage(size, [UIScreen mainScreen].scale);
    }    
    delete data;
    return rv;
}

#pragma mark properties
- (void) setStateActive:(int)state
{
    _render->setStateActive(state);
}

- (void) setStateInactive:(int)state
{
    _render->setStateInactive(state);
}

- (void) setAllStatesInactive
{
    _render->setAllStatesInactive();
}


- (void) setState:(int)state active:(BOOL)active
{
    if(active)
    {
        _render->setStateActive(state);
    }else
    {
        _render->setStateInactive(state);
    }
}


-(void) setSvgFile:(NSString *)svgFile
{
    if(![_svgFile isEqualToString:svgFile])
    {
#if !HAVE_ARC
        [_svgFile release];
        _svgFile = [svgFile retain];
#else
        _svgFile = svgFile;
#endif        
        @synchronized(self)
        {
            if(_svgFile==nil)
            {
                _render->close();
            }else
            {
                if(_render->openFile([_svgFile UTF8String]))
                {
                    _render->prepareToDrawData();
                }
            }
        }
    }
}

-(NSString *) svgFile
{
    return _svgFile;
}



@end
