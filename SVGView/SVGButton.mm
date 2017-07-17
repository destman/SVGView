//
//  SVGButton.m
//  SVGViewTest
//
//  Created by Arkadiy Tolkun on 31.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGButton.h"
#import "SVGRender.hpp"

@implementation SVGButton

- (void) _init
{
    _render = new SVGRender();
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

- (void) renderImages
{
    dbgLog(@"RenderingImages");
    CGSize size = self.bounds.size;
    double scale = [UIScreen mainScreen].scale;
    
    _render->setStateActive(0);
    [self setBackgroundImage:_render->createUIImage(size, scale) forState:UIControlStateNormal];
    _render->setStateInactive(0);
    
    if(_render->haveState(1))
    {
        _render->setStateActive(1);
        [self setBackgroundImage:_render->createUIImage(size,scale) forState:UIControlStateHighlighted];
        _render->setStateInactive(1);
    }
    if(_render->haveState(2))
    {
        _render->setStateActive(2);
        [self setBackgroundImage:_render->createUIImage(size,scale) forState:UIControlStateSelected];
        _render->setStateInactive(2);
    }
    dbgLog(@"Finished rendering images");    
}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if([super pointInside:point withEvent:event])
    {
        CGSize size = self.bounds.size;
        if(_render->haveState(0))
        {
            _render->setStateActive(0);
        }
        BOOL rv = _render->isPointInside(point,size);
        _render->setStateInactive(0);
        return rv;
    }
    return NO;
}

#pragma mark properties
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
        [self renderImages];
    }
}

-(NSString *) svgFile
{
    return _svgFile;
}


@end
