//
//  AppDelegate.m
//  SVGViewTest
//
//  Created by Arkadiy Tolkun on 31.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "TestViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    _navCtl = [[UINavigationController alloc] initWithRootViewController:[[TestViewController alloc] initWithNibName:nil bundle:nil]];
    [_navCtl setNavigationBarHidden:YES];

    [_window addSubview:_navCtl.view];
    [_window makeKeyAndVisible];
    return YES;
}

@end
