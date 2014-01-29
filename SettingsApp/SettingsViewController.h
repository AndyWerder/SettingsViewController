//
//  SettingsViewController.h
//  ChefsHand
//
//  Created by Andreas Werder on 1/12/14.
//  Copyright (c) 2014 Material Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SPTypeDefault = 0,
    SPTypeString,
    SPTypeInteger32,
    SPTypeBoolean,
    SPTypeSimpleList,
    SPTypeChoice,            // This is used for MultiValue type on the lower level
    SPTypeMultiLevel = 10,
    SPTypeMultiValue,
    SPTypePList,
    SPTypeAction
} SettingsPropertyType;


// Macros for setting up the property lists
#define P_SECTION(TITLE, HEADER, ROWS, FOOTER) @{@"title": TITLE, @"type": @(SPTypePList), @"header": HEADER, @"rows": ROWS, @"footer": FOOTER }
#define P_ROW(NAME, TYPE, VALUE, EDIT, KEYBOARDTYPE, FLAGS, IDENTIFIER) @{@"name": NAME, @"type": @(TYPE), @"value": VALUE, @"edit": @(EDIT), @"kbType": @(KEYBOARDTYPE), @"flags": FLAGS, @"identifier": IDENTIFIER }
#define P_MULTIVALUE(NAME, VALUE) @{@"name": NAME, @"value": VALUE }


@protocol SettingsViewControllerDelegate <NSObject>

- (NSDictionary *)settingsInput:(id)sender;
- (void)settingsDidChange:(id)value forKey:(NSString *)name;
- (void)didDismissModalView:(id)sender;

@end

@interface SettingsViewController : UITableViewController

@property (nonatomic, assign) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSDictionary *valuesIn;
@property (nonatomic, strong) NSMutableDictionary *valuesOut;

@property (nonatomic, assign) NSInteger nestingLevel;

- (id)initWithProperties:(NSArray *)properties;

@end

@interface SettingsViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) NSDictionary *rowDictionary;
@property (readonly, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, weak) SettingsViewController *viewController;

- (void)switchOnOff:(id)sender;

@end
