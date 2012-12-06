//
//  TestViewController.h
//  SVGViewTest
//
//  Created by Arkadiy Tolkun on 31.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGView.h"
#import "SVGButton.h"

@interface TestViewController : UIViewController
{
    IBOutlet  SVGView *testView;
    IBOutlet  SVGButton *testButton;
    IBOutlet  UIImageView *imageView;
}

@end
