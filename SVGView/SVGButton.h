//
//  SVGButton.h
//  SVGViewTest
//
//  Created by Arkadiy Tolkun on 31.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVGButton : UIButton
{
    struct SVGRender *_render;
    NSString         *_svgFile;
}

@property(retain) NSString * svgFile;

/**
 Call this function to render images for button
 */
- (void) renderImages;
@end
