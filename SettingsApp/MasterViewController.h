//
//  MasterViewController.h
//  SettingsApp
//
//  Created by Andreas Werder on 1/19/14.
//  Copyright (c) 2014 Andreas Werder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@class DetailViewController;

typedef enum {
  
    BackgroundColorWhite = 0,
    BackgroundColorYellow,
    BackgroundColorGreeen,
    BackgroundColorBlue
    
} BackgroundColor;


@interface MasterViewController : UITableViewController <SettingsViewControllerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

- (void)settings;

@end

@interface MasterViewControllerCell : UITableViewCell

@end