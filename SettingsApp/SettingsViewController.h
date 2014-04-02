//
//  SettingsViewController.h
//  ChefsHand
//
//  Created by Andreas Werder on 1/12/14.
//  Copyright (c) 2014 Material Apps. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>

typedef enum {
    SPTypeDefault = 0,
    SPTypeString,
    SPTypeInteger32,
    SPTypeBoolean,
    SPTypeMultilineText,
    SPTypeHTML,
    SPTypeSimpleList,
    SPTypeChoice,            // This is used for MultiValue type on the lower level
    SPTypeMultiLevel = 10,
    SPTypeMultiValue,
    SPTypePList,
    SPTypeAction
} SettingsPropertyType;

//  Create the property list as an array of dictionaries. Each element in the array must be a
//  NSDictionary of values defining one property group (or section in UITableView terms). A group
//  consists of:
//  -   a title
//  -   a number of properties (or rows)
//  -   a header and footer
//
//  The P_SECTION macro can be used to build the dictionary structure for a group or section.
//  The section includes an array of dictionaries where one dictionary defines a property in the
//  group. A property (or row) consists of:
//  -   a name
//  -   a type - where valid types are defined by the SettingsPropertyType enum.
//  -   a value - a number (integer or float) associated with the name
//  -   an edit flag indicating if the row value can be edited
//  -   a keyboard type of type UIKeyboardType
//  -   a string of additional flags
//  -   and an identifier which must reference a name/value pair in the the input value list.
//
//  The SettingsViewController supports strings, numbers, boolean values and multi-value choices.
//  Furthermore it allows to have nested property list. A row on level 1 can consist of a group
//  (or section) of properties on level 2. See the SettingsViewController.m header for more details.
//
// Macros for setting up the property lists

#define P_SECTION(TITLE, HEADER, ROWS, FOOTER) @{@"title": TITLE, @"type": @(SPTypePList), @"header": HEADER, @"rows": ROWS, @"footer": FOOTER }
#define P_ROW(NAME, TYPE, VALUE, EDIT, KEYBOARDTYPE, FLAGS, IDENTIFIER) @{@"name": NAME, @"type": @(TYPE), @"value": VALUE, @"edit": @(EDIT), @"kbType": @(KEYBOARDTYPE), @"flags": FLAGS, @"identifier": IDENTIFIER }
#define P_MULTIVALUE(NAME, VALUE) @{@"name": NAME, @"value": VALUE }


@protocol SettingsViewControllerDelegate <NSObject>

- (NSDictionary *)settingsInput:(id)sender;

@optional
- (void)settingsDidChange:(id)value forKey:(NSString *)name;
- (void)willDismissModalView:(id)sender;
- (void)didDismissModalView:(id)sender;

@end

@interface SettingsViewController : UITableViewController

@property (nonatomic, assign) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSDictionary *valuesIn;
@property (nonatomic, strong) NSMutableDictionary *valuesOut;

@property (nonatomic, assign) NSInteger nestingLevel;

- (id)initWithProperties:(NSArray *)properties;
- (void)didChange:(id)value forKey:(NSString *)name;

@end

@interface SettingsViewCell : UITableViewCell <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) NSDictionary *rowDictionary;
@property (readonly, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, weak) SettingsViewController *viewController;

- (void)switchOnOff:(id)sender;
- (void)buttonSelected:(id)sender;

@end
