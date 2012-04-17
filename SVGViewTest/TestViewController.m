//
//  TestViewController.m
//  SVGViewTest
//
//  Created by Arkadiy Tolkun on 31.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TestViewController.h"

@implementation TestViewController

-(void) dealloc
{
    
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if( (self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) )
    {
    }
    
    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    testView.svgFile   = [[NSBundle mainBundle] pathForResource:@"main_bg.svgpb" ofType:@""];
    testButton.svgFile = [[NSBundle mainBundle] pathForResource:@"btn_test.svgpb" ofType:@""];
}



@end
