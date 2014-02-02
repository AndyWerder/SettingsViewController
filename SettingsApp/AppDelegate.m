//
//  AppDelegate.m
//  SettingsApp
//
//  Created by Andreas Werder on 1/19/14.
//  Copyright (c) 2014 Andreas Werder. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOption {
    
    // Override point for customization after application launch.
    // Initialize main window, the navigation controller with navigation bar and buttons as well as the segmented controllers

	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    MasterViewController *masterViewController = [[MasterViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *mnc = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    [window setRootViewController:mnc];
    [window makeKeyAndVisible];
    
    return YES;
}

@end
