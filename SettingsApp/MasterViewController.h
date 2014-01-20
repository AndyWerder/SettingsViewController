//
//  MasterViewController.h
//  SettingsApp
//
//  Created by Andreas Werder on 1/19/14.
//  Copyright (c) 2014 Andreas Werder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
