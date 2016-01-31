//
//  SettingsViewController.h
//  ChefsHand
//
//  Created by Andreas Werder on 1/12/14.
//  Copyright (c) 2014, 2015 Material Apps. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//
//  Changes history:
//  2015-09-07  Introduced 2 new macros P_GET/SET_ARRAY to facilitate indexed properties
//

#import <UIKit/UIKit.h>

typedef enum {
    SPTypeDefault = 0,
    SPTypeString,
    SPTypeInteger32,
    SPTypeDecimal,
    SPTypeBoolean,
    SPTypeDate,
    SPTypeMultilineText,
    SPTypeHTML,
    SPTypeSimpleList,
    SPTypeCustom,
    SPTypeChoice,            // This is used for MultiValue type on the lower level
    SPTypeMultiLevel = 20,
    SPTypeMultiValue,
    SPTypePickerList,
    SPTypePList,
    SPTypeAction,
    SPTypePickerView         // This is used for PickerList type on the lower level
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

#define P_SECTION(TITLE, KEY, HEADER, ROWS, FOOTER) @{@"title": TITLE, @"type": @(SPTypePList), @"header": HEADER, @"rows": ROWS, @"footer": FOOTER, @"key": KEY }
#define P_ROW(NAME, TYPE, VALUE, EDIT, KEYBOARDTYPE, FLAGS, IDENTIFIER) @{@"name": NAME, @"type": @(TYPE), @"value": VALUE, @"edit": @(EDIT), @"kbType": @(KEYBOARDTYPE), @"flags": FLAGS, @"identifier": IDENTIFIER }
#define P_MULTIVALUE(NAME, VALUE) @{@"name": (NAME), @"value": (VALUE) }

#define P_SET_ARRAY(NAME, IDX, VALUE) ([NSDictionary dictionaryWithObject:VALUE forKey:[NSString stringWithFormat:@"%@%ld", NAME, (long)IDX]])
#define P_GET_ARRAY(NAME, IDX) ([NSString stringWithFormat:@"%@%ld", NAME, (long)IDX])


@class SettingsViewCell;
@class SettingsTextView, SettingsTextField;

@protocol SettingsViewControllerDelegate <NSObject>

- (NSDictionary *)settingsInput:(id)sender;

@optional
- (NSArray *)willChangePropertiesForRow:(NSDictionary *)rowDictionary;
- (void)didChangePropertiesForRow:(NSDictionary *)rowDictionary;
- (NSDictionary *)settingsDefault:(id)sender;
- (void)settingsDidChange:(id)value forRow:(NSDictionary *)row;
- (NSArray *)refreshPropertiesList:(NSArray *)properties;
- (void)willDismissModalView:(id)sender;
- (void)didDismissModalView:(id)sender;
- (CGFloat)customSetting:(id)settingsViewController heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)customSetting:(id)settingsViewController commitDeleteForRowAtIndexPath:(NSIndexPath *)indexPath;
- (SettingsViewCell *)customSetting:(SettingsViewCell *)cell cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)customSetting:(SettingsViewCell *)cell didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)customSetting:(id)settingsViewController layoutSubviews:(SettingsViewCell *)cell;
- (void)customSetting:(id)settingsViewController touchedView:(UIView *)view;


@end

@interface SettingsViewController : UITableViewController

@property (nonatomic, strong) NSArray *propertyList;
@property (nonatomic, strong, readonly) NSDictionary *rowDictionary;
@property (nonatomic, strong) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSDictionary *valuesIn;
@property (nonatomic, strong) NSMutableDictionary *valuesOut;
@property (nonatomic, strong) NSDictionary *valuesDefault;
@property (nonatomic, strong) NSString *valuesId;
@property (nonatomic, strong) UIMenuController *menuController;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) SettingsViewController *settingsViewController;

@property (nonatomic, assign) NSInteger nestingLevel;

- (id)init;
- (void)setPropertiesForRow:(NSDictionary *)row;
- (void)didChange:(id)value forKey:(NSString *)name;
- (void)didChange:(id)value forRow:(NSDictionary *)row;
- (void)dismissViewController;
- (NSDictionary *)rowForIndexPath:(NSIndexPath *)indexPath;
- (void)reset;

@end

@interface SettingsViewCell : UITableViewCell <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) NSDictionary *rowDictionary;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) SettingsTextView *textView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, weak) SettingsViewController *viewController;

// This weird fix is needed to get the SettingsViewController running in iOS 8 Beta 5
@property (readwrite, strong) UIInputViewController *inputViewController;

- (void)switchOnOff:(id)sender;
- (void)buttonSelected:(id)sender;
+ (void)resetLastEditedField;

@end

@interface SettingsPickerView : UIPickerView <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong, getter=parentCell, setter=setParentCell:) SettingsViewCell *parentCell;
@property (nonatomic, strong, getter=choices, setter=setChoices:) NSArray *choices;

@end


@interface SettingsTextView : UITextView

@end
