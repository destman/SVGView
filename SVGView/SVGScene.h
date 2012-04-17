//
//  SVGScene.h
//  IPhoneSpeedTracker
//
//  Created by Arkadiy Tolkun on 06.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGView.h"

typedef void(^SVGSceneAction)(UITouch  *touch, int state, BOOL stillInside);

BOOL isTouchDown(UITouchPhase phase);
BOOL isTouchUP(UITouchPhase phase);

@interface SVGScene : SVGView
{
    NSMutableDictionary *_actions;
    
    NSMutableDictionary *_touchesStartPoints;
}

-(void) setAction:(SVGSceneAction)action forState:(int) state;

//last action must be negative
-(void) setAction:(SVGSceneAction)action forStates:(int) first,...;

-(void) setButtonNormalState:(int)normalState highlightedState:(int)highlihtedState event:(dispatch_block_t)event;


@end
