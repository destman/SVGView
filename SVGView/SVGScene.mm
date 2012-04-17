//
//  SVGScene.m
//  IPhoneSpeedTracker
//
//  Created by Arkadiy Tolkun on 06.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGScene.h"
#import "SVGRender.h"

BOOL isTouchDown(UITouchPhase phase)
{
    return (phase==UITouchPhaseBegan || phase==UITouchPhaseMoved || phase==UITouchPhaseStationary);
}

BOOL isTouchUP(UITouchPhase phase)
{
    return phase==UITouchPhaseEnded;
}


@implementation SVGScene

-(void) _internalInit
{
    _actions            = [[NSMutableDictionary alloc] init];
    _touchesStartPoints = [[NSMutableDictionary alloc] init];
}

-(void) dealloc
{
    [_actions release];
    [_touchesStartPoints release];
    [super dealloc];
}

-(id) initWithFrame:(CGRect)frame
{
    if( (self=[super initWithFrame:frame]) )
    {
        [self _internalInit];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if( (self=[super initWithCoder:aDecoder]) ) 
    {
        [self _internalInit];
    }
    return self;
}

-(void) setAction:(SVGSceneAction)action forState:(int) state
{
    SVGSceneAction copyOfAction = [action copy];
    [_actions setObject:copyOfAction forKey:[NSNumber numberWithInt:state]];
    [copyOfAction release];
}

-(void) setAction:(SVGSceneAction)action forStates:(int) first,...
{
    SVGSceneAction copyOfAction = [action copy];
	va_list vl;
	va_start(vl,first);
    int state=first;
    while(state>=0)
    {
        [_actions setObject:copyOfAction forKey:[NSNumber numberWithInt:state]];
        state = va_arg(vl, int);
    }
	va_end(vl);	    
    [copyOfAction release];
}


-(void) setButtonNormalState:(int)normalState highlightedState:(int)highlihtedState event:(dispatch_block_t)event
{
    _render->setStateActive(normalState);
    [self setAction:^(UITouch *touch, int state, BOOL stillInside) 
    {
        if(state==normalState)
        {
            if(isTouchDown(touch.phase) && stillInside)
            {
                _render->setStateInactive(normalState);
                _render->setStateActive(highlihtedState);
                [self setNeedsDisplay];
            }
        }if(state==highlihtedState)
        {
            if(isTouchUP(touch.phase))
            {
                _render->setStateInactive(highlihtedState);
                _render->setStateActive(normalState);
                if(stillInside)
                {
                    event();
                }
                [self setNeedsDisplay];
            }            
        }
    } forStates:normalState, highlihtedState,-1];
}

-(void) invokeActionsForTouch:(UITouch *)touch
{
    @synchronized(self)
    {
        CGSize  size = self.bounds.size;
        CGPoint pos;
        CGPoint curPos = [touch locationInView:self];
        NSValue *startPosValue = [_touchesStartPoints objectForKey:[NSNumber numberWithInt:touch.hash]];
        if(startPosValue)
        {
            pos = [startPosValue CGPointValue];
        }else
        {
            pos = curPos;
        }
        
        set<int> curStates = _render->statesAtPoint(curPos, size);
        set<int> states = _render->statesAtPoint(pos,size);
        for (set<int>::const_iterator it=states.begin(); it!=states.end(); ++it) 
        {
            SVGSceneAction action = [_actions objectForKey:[NSNumber numberWithInt:*it]];
            if(action)
            {
                action(touch, *it,curStates.find(*it)!=curStates.end());
            }
        }
    }
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in touches)
    {
        [_touchesStartPoints setObject:[NSValue valueWithCGPoint:[touch locationInView:self]] 
                                forKey:[NSNumber numberWithInt:touch.hash]]; 
        [self invokeActionsForTouch:touch];
    }
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in touches)
    {
        NSValue *startPosValue = [_touchesStartPoints objectForKey:[NSNumber numberWithInt:touch.hash]];    
        if(startPosValue)
        {
            [self invokeActionsForTouch:touch];
        }
    }
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in touches)
    {
        NSValue *startPosValue = [_touchesStartPoints objectForKey:[NSNumber numberWithInt:touch.hash]];    
        if(startPosValue)
        {
            [self invokeActionsForTouch:touch];
            [_touchesStartPoints removeObjectForKey:[NSNumber numberWithInt:touch.hash]];
        }
    }
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in touches)
    {
        NSValue *startPosValue = [_touchesStartPoints objectForKey:[NSNumber numberWithInt:touch.hash]];    
        if(startPosValue)
        {
            [self invokeActionsForTouch:touch];
            [_touchesStartPoints removeObjectForKey:[NSNumber numberWithInt:touch.hash]];
        }
    }
}

@end
