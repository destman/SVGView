//
//  SVGView.h
//  SVGView
//
//  Created by destman on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVGView : UIView
{
    struct SVGRender *_render;
    NSString *_svgFile;
}

@property(retain) NSString * svgFile;

- (void) prepareToDraw;
+ (UIImage *) imageWithSize:(CGSize) size fromSVGFile:(NSString *)fullFileName;

- (void) setStateActive:(int)state;
- (void) setStateInactive:(int)state;
- (void) setAllStatesInactive;
- (void) setState:(int)state active:(BOOL)active;

@end
