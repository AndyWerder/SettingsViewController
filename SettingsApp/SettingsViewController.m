//
//  SettingsViewController.m
//  ChefsHand
//
//  Created by Andreas Werder on 1/12/14.
//  Copyright (c) 2014 Material Apps. All rights reserved.
//
//  Changes history:
//  2014-01-12  Initial implementation - totally property list driven
//  2014-01-26  Added implementation of settings type Action (button)
//  2014-01-27  Added implementation of settings type simple list
//  2014-03-03  Added implementation of settings type multi-line text view
//  2014-03-09  Added implementation of settings type HTML text view
//
//  Self-contained class to provide an iPad Settings app-like user interface for managing
//  application specific settings. SettingsViewController is a subclass of UITableView and
//  uses the grouped style. It supports multiple nesting levels. The settings are managed
//  by a property list kept in an NSDictionary as properties. The property list is built
//  outside of the class. The SettingsViewController.h file provides macros for facilitating
//  the building the property list.
//
//  SettingsViewController supports several types of settings:
//  Single level types:
//  - String            Single line strings can be used for names, credentials (including
//                      passwords). A number of settings parameters support keyboard type,
//                      auto-correction and capitalization plus password obfuscation.
//  - Integer           Yet to be implemented
//  - Boolean           The user interface for Boolean settings is based on the switch
//                      (UISwitch) control.
//  - Multi-line text   Provides a textView that spans across the entire cell for free text
//                      entry and editing.
//  - HTML              Provides a webView that spans across the entire cell for presenting
//                      HTML content.
//  - Simple list       A list of mutually exclusive choices. The value of the selected
//                      row becomes the result. The simple list is similar to the multi-
//                      value list except that it presents all choices on the current
//                      level.
//
//  Multi-level types:  Invoke the SettingsViewController recursively for as many levels
//                      as required.
//
//  - Multi-value       Provides a drop-down list like interface using a second level
//                      of the SettingsViewController. The multi-value type is based on
//                      a title-value tuple per choice. The controller displays the title
//                      but the result returned is given by the corresponding value for
//                      the title.
//  - Property list     The property list is again a dictionary with the same structure as
//                      the top level property list. Any level of recursive nesting is
//                      supported.
//  - Action            The action type is implemented with a custom style UIButton. The
//                      button title can be configured for several UIControlState values
//                      thus permitting On/Off kind or even multi-state buttons. A button
//                      can trigger one selector which must be implemented by the
//                      SettingViewController Delegate (but which is not part of the Delegate
//                      protocol).
//
//  Input Values        The initial settings to be used in the property list must be provided
//                      in a (flat) NSDictionary structure of name/value tuples.
//  Output Values       Changed values are provided in a NSMutableDictionary with the same
//                      structure as the input values, i.e. name/value tuples. Only changed
//                      values are returned in the output values dictionary. If no changes
//                      have been made, the resulting dictionary will be empty.
//
//  Delegate Protocol:  The SettingsViewController uses provides protocol for mandatory and
//                      optional methods to be implemented by the calling class.
//
//  -settingsInput:sender:
//                      Callback used to provide a dictionary of name/value tuples to be
//                      used as initial values in the propery lists. The names of the values
//                      presented must match the identifier provided for the particular
//                      property.
//
//  -settingsDidChange:forKey:
//                      Callback that is invoked in the protocol delegate whenever a value
//                      from the property list has been changed by the user.
//
//  -didDismissModalView:
//                      Callback that must implement one of the dismissController methods
//                      used by the UIViewController class to release a controller.
//


#import "SettingsViewController.h"

static NSString *cellIdentifier;
static NSString *headerViewIdentifier;

@interface SettingsViewController () {
    
    SettingsViewController *settingsViewController;
    NSArray *pList;
}
- (NSDictionary *)rowForIndexPath:(NSIndexPath *)indexPath;
@end


@implementation SettingsViewController

@synthesize delegate, nestingLevel, valuesIn, valuesOut;

- (id)initWithProperties:(NSArray *)properties {
    
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
        // Custom initialization
        [self setTitle:@"Settings"];
        nestingLevel = 0;
        pList = properties;
        valuesOut = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        // Initialize tableView
        [self.tableView setDelegate:self];
        [self.tableView setDataSource:self];
        
        // TableView configuration. We register the subclass of UITableViewCell to
        // get a protoype. The cell is initialized in initWithStyle:reuseIdentifier:.
        
        cellIdentifier = @"SettingsViewCell";
        [self.tableView registerClass:[SettingsViewCell class]
               forCellReuseIdentifier:cellIdentifier];
        
        headerViewIdentifier = @"SectionHeaderView";
        [self.tableView registerClass:[UITableViewHeaderFooterView class]
            forHeaderFooterViewReuseIdentifier:headerViewIdentifier];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // This callback is invoked in two cases:
    //
    //  1)  When the SettingsViewController is invoked initially and displayed on the top-level and
    //  2)  when control is given back from a SettingsViewController instance on the lower level
    //      after a property sub-list was viewed or the user has made a choice from a multi-value list.
    //
    // To distinguish we simply check if the settingsViewController instance is nil (case 1) or
    // non-nil (case 2).
    
    
    if (!settingsViewController) {
        
        // Case 1: Initialize valuesOut mutable dictionary.
        
        if (nestingLevel == 0) {
            
            // Overwrite the right button to show a Done button which is used to dismiss the modal
            // view. We do this only on the entry level for the settingsViewController.
            
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self action:@selector(dismissView:)];
            
            // Now get the settings initial values; they will be carried in valuesIn while
            // changed settins are in valuesOut.
            
            if ([delegate respondsToSelector:@selector(settingsInput:)])
                valuesIn = [delegate settingsInput:self];
            valuesOut = [[NSMutableDictionary alloc] initWithCapacity:5];
        }
        
    } else {
        
        // Case 2: Merge changes of values from lower levels with changes on current level.
        [valuesOut addEntriesFromDictionary:settingsViewController.valuesOut];
        valuesIn = [self mergeValues:valuesOut];
        
    }
    
    // We release the instance from a lower level in any case as we want to start from
    // a clear slate on this level again.
    
    settingsViewController = nil;
    [self.tableView reloadData];
}

#pragma mark - SettingsViewController internal methods that invoke delegate protocol methods

- (void)didChange:(id)value forKey:(NSString *)name {
    
    // Captures a changed value and updates the valueOut mutable dictionary. It also
    // re-builds the valueIn dictionary. When completed it then gives the protocol delegate
    // a chance to take action.
    // Only change the value if it is different from the previous generation.
    
    if (![value isEqual:[valuesIn valueForKey:name]]) {
        // NSLog(@"Changing value for key(%@), replacing new(%@) for old(%@)", name, value,
        //      [valuesIn valueForKey:name]);
        NSDictionary *dictionary = [NSDictionary dictionaryWithObject:value forKey:name];
        [valuesOut addEntriesFromDictionary:dictionary];
        valuesIn = [self mergeValues:valuesOut];
        
        // Invoke protocol delegate method if defined.
        if ([delegate respondsToSelector:@selector(settingsDidChange:forKey:)])
            [delegate performSelector:@selector(settingsDidChange:forKey:) withObject:value withObject:name];
    }
}

- (void)dismissView:(id)sender {
    
    // Call the two delegate methods to dismiss the modal view.
    if ([delegate respondsToSelector:@selector(willDismissModalView:)])
        [delegate willDismissModalView:sender];
    if ([delegate respondsToSelector:@selector(didDismissModalView:)])
        [delegate didDismissModalView:sender];
}

- (NSDictionary *)mergeValues:(NSMutableDictionary *)updatedKeys {
    
    // Merge the updated values into the initial set so that we can update.
    NSMutableDictionary *tmp = [valuesIn mutableCopy];
    [tmp addEntriesFromDictionary:updatedKeys];
    
    return tmp;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return [pList count];
}

- (NSDictionary *)rowForIndexPath:(NSIndexPath *)indexPath {
    
    // Auxiliary method to select the rows based on indexPath and type.
    NSArray *sectionArray = [pList objectAtIndex:indexPath.section];
    NSArray *rows = [sectionArray valueForKey:@"rows"];
    NSDictionary *firstRow = [rows firstObject];
    
    if ([[firstRow valueForKey:@"type"] integerValue] == SPTypeSimpleList)
        return firstRow;
    else
        return [rows objectAtIndex:indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger numberOfRows = 0;
    NSArray *sectionArray = [pList objectAtIndex:section];
    NSArray *rows = [sectionArray valueForKey:@"rows"];
    numberOfRows = [rows count];
    
    if (numberOfRows == 1 && [[[rows firstObject] valueForKey:@"type"] integerValue] == SPTypeSimpleList) {
        NSArray *choices = [[rows valueForKey:@"value"] firstObject];
        numberOfRows = [choices count];
    }
    
    return numberOfRows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the row definition
    BOOL canEdit = NO;
    
    NSDictionary *section = [pList objectAtIndex:indexPath.section];
    NSArray *rows = [section valueForKey:@"rows"];
    
    // If we have a type unequal to SPTypeSimpleList then we can take the edit flag from
    // the row. Simple lists cannot be edited, so we return a NO for those.
    
    if ([[[rows firstObject] valueForKey:@"type"] integerValue] != SPTypeSimpleList) {
        NSDictionary *rowDictionary = [[section valueForKey:@"rows"] objectAtIndex:indexPath.row];
        if ([[rowDictionary valueForKey:@"edit"] boolValue])
            canEdit = YES;
        else
            canEdit = NO;
    }
    return canEdit;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat rowHeight = UITableViewAutomaticDimension;
    NSDictionary *section = [pList objectAtIndex:indexPath.section];
    NSArray *rows = [section valueForKey:@"rows"];
    NSString *detailText;

    // We first need to check if this is a simple list to avoid index out of range error; then
    // we check if we have a multi-line text view. If so, we take a height large enough for a bunch
    // of lines.
    
    if ([[[rows firstObject] valueForKey:@"type"] integerValue] != SPTypeSimpleList) {
        NSDictionary *row = [rows objectAtIndex:indexPath.row];
        SettingsPropertyType type = (SettingsPropertyType)[[row valueForKey:@"type"] integerValue];
        if (type == SPTypeMultilineText || type == SPTypeHTML) {
            
            id tmp = [valuesIn valueForKey:[row valueForKey:@"identifier"]];
            if ([NSStringFromClass([tmp class]) isEqualToString:@"NSNull"])
                detailText = @"";
            detailText = [NSString stringWithFormat:@"%@", tmp];
            BOOL editMode = [[row valueForKey:@"edit"] boolValue];
            
            CGSize maximumLabelSize = CGSizeMake(tableView.frame.size.width, CGFLOAT_MAX);
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            CGRect frame = [detailText boundingRectWithSize:maximumLabelSize
                                                options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                             attributes:@{NSFontAttributeName: font}
                                                context:nil];
            // We give quite a bit of empty space initially and also add 3 to 4 empty lines if in edit mode.
            rowHeight = ([detailText length] == 0) ? MAX(250.0, frame.size.height) : MAX(40.0, frame.size.height) + editMode * 50.0f;
        }
    }

    return rowHeight;
}

#pragma mark - Table view header and footer view definitions

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    // We display the section title for all types of properties except a multi-value list
    // in an envelope where we don't want to display the synthetic envelope layer.
    
    NSString *title;
    SettingsPropertyType type = (SettingsPropertyType)[[[pList objectAtIndex:section] valueForKey:@"type"] integerValue];
    if (type != SPTypeMultiValue)
        title = [[pList objectAtIndex:section] valueForKey:@"title"];
    else
        title = @"";
    
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    // The tableView:heightForHeaderInSection: delegate method must be present so that
    // the tableView:viewForHeaderInSection: is called. 

    CGFloat headerHeight = UITableViewAutomaticDimension;
    SettingsPropertyType type = (SettingsPropertyType)[[[pList objectAtIndex:section] valueForKey:@"type"] integerValue];
    NSString *header = [[pList objectAtIndex:section] valueForKey:@"header"];
    
    if (type != SPTypeMultiValue && ![header isEqual:[NSNull null]]) {
        CGSize maximumLabelSize = CGSizeMake(tableView.frame.size.width, CGFLOAT_MAX);
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        CGRect frame = [header boundingRectWithSize:maximumLabelSize
                                                 options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                              attributes:@{NSFontAttributeName: font}
                                                 context:nil];
        headerHeight = 50.0 + frame.size.height;
    }
    return headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    // Provide a reusable tableview header/footer view if a header text is present. Otherwise
    // just return nil and let the viewController deal with sizing the view.

    NSString *title, *header;
    UITableViewHeaderFooterView *sectionHeaderView;
    
    SettingsPropertyType type = (SettingsPropertyType)[[[pList objectAtIndex:section] valueForKey:@"type"] integerValue];
    sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewIdentifier];
    
    if (type != SPTypeMultiValue) {
        title = [[pList objectAtIndex:section] valueForKey:@"title"];
        header = [[pList objectAtIndex:section] valueForKey:@"header"];
    } else {
        title = @"";
        header = [[pList objectAtIndex:section] valueForKey:@"header"];
    }
    
    // If we have a title we just use the default header for a group title. If the title is empty but
    // the header is defined we use a header instead and provide a view. The header text will then
    // go into the text field of the detail label.

    if ([title length] > 0) {
        [sectionHeaderView.textLabel setText:title];
    }
    
    if (![header isEqual:[NSNull null]]) {
        if ([header length] > 0) {
            [sectionHeaderView.textLabel setText:title];
            [sectionHeaderView.detailTextLabel setText:header];
        }
    }
    return sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    // The tableView:heightForFooterInSection: delegate method must be present so that
    // the tableView:viewForFooterInSection: is called.
    
    CGFloat footerHeight = UITableViewAutomaticDimension;
    SettingsPropertyType type = (SettingsPropertyType)[[[pList objectAtIndex:section] valueForKey:@"type"] integerValue];
    NSString *footer = [[pList objectAtIndex:section] valueForKey:@"footer"];
    
    if (type != SPTypeMultiValue && ![footer isEqual:[NSNull null]]) {
        CGSize maximumLabelSize = CGSizeMake(tableView.frame.size.width, CGFLOAT_MAX);
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        CGRect frame = [footer boundingRectWithSize:maximumLabelSize
                                            options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                         attributes:@{NSFontAttributeName: font}
                                            context:nil];
        footerHeight = MAX(28.0, frame.size.height);
    }
    return footerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    // Provide a reusable tableview header/footer view if a header text is present. Otherwise
    // just return nil and let the viewController deal with sizing the view.
    
    NSString *footer = [[pList objectAtIndex:section] valueForKey:@"footer"];
    UITableViewHeaderFooterView *sectionFooterView;
    
    sectionFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewIdentifier];
    
    // If we have a title we just use the default header for a group title. If the title is empty but
    // the header is defined we use a header instead and provide a view. The header text will then
    // go into the text field of the detail label.
    
    if (![footer isEqual:[NSNull null]]) {
        if ([footer length] > 0) {
            [sectionFooterView.textLabel setText:footer];
        }
    }
    return sectionFooterView;
}

#pragma mark - Table view cell configuration

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // We have registered the class so this always gives us a valid cell.
    SettingsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                             forIndexPath:indexPath];
    
    // Get the row definition; take the row using indexPath into rows when not SPTypeSimpleList.
    NSDictionary *rowDictionary = [self rowForIndexPath:indexPath];
    
    SettingsPropertyType type;
    UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
    UITableViewCellSelectionStyle selectionStyle = UITableViewCellSelectionStyleNone;
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    UISwitch *accessoryView;
    CGFloat maxRowHeight = 400.0f;
    NSDictionary *choicesDictionary;
    NSString *formatted;
    
    // Configure the cell and determine type required.
    [cell setViewController:self];
    [cell setTag:indexPath.row];
    [cell setRowDictionary:rowDictionary];
    type = (SettingsPropertyType)[[rowDictionary valueForKey:@"type"] integerValue];

    // Clean up the cell from: remove textView and button if we had some from previous runs.
    if (type != SPTypeMultilineText && type != SPTypeHTML)
        if (cell.textView)
            [cell.textView removeFromSuperview];
    if (type != SPTypeAction)
        if (cell.button)
            [cell.button removeFromSuperview];

    // Get flags for the editing and keyboard properties of the detail text label.
    BOOL editable = [[rowDictionary valueForKey:@"edit"] boolValue];
    NSString *flags = [rowDictionary valueForKey:@"flags"];
    BOOL capitalized = NSNotFound != [flags rangeOfCharacterFromSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"c"]].location;
    BOOL autocorrect = NSNotFound != [flags rangeOfCharacterFromSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"a"]].location;
    BOOL secure = NSNotFound != [flags rangeOfCharacterFromSet:
                                 [NSCharacterSet characterSetWithCharactersInString:@"s"]].location;
    [cell.textLabel setText:[rowDictionary valueForKey:@"name"]];
    
    // Extract the value for the key from the property list dictionary - if there is one.
    id value, choices;
    NSString *identifier = [rowDictionary valueForKey:@"identifier"];
    if (identifier)
        value = [valuesIn valueForKey:identifier];
    choices = [rowDictionary valueForKey:@"value"];
    
    switch (type) {
        case SPTypeString:
            
            // We have a string - display it. But first, set keyboard type and secure
            // text attributes if required.
            
            if (editable) {
                keyboardType = [[rowDictionary valueForKey:@"kbType"] integerValue];
                [cell.textField setKeyboardType:keyboardType];
                if (capitalized)
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                else
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
                if (autocorrect)
                    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeYes];
                else
                    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            }
            // Obfuscate text string, e.g. a password.
            if (secure)
                [cell.textField setSecureTextEntry:YES];
            else
                [cell.textField setSecureTextEntry:NO];
            if ([(NSString *)value length] > 0)
                [cell.detailTextLabel setText:(NSString *)value];
            else
                [cell.detailTextLabel setText:@" "];
            [cell.textField setEnabled:editable];
            break;
            
        case SPTypeInteger32:
            //
            break;
            
        case SPTypeBoolean:
            
            // The boolean type is implemented with the On/Off switch - just like in the
            // Settings app.
            
            accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
            [accessoryView setOn:[value boolValue]];
            [accessoryView addTarget:cell action:@selector(switchOnOff:)
                    forControlEvents:UIControlEventValueChanged];
            [accessoryView setUserInteractionEnabled:editable];
            break;
            
        case SPTypeMultilineText:
        case SPTypeHTML:

            // Allocate a textview for the multi-line text field only if there isn't one
            // there from before. Make sure we always hav a string to display.

            if (value)
                formatted = [NSString stringWithFormat:@"%@", value];
            else
                formatted = @"";
            maxRowHeight = ([formatted length] > 0) ? 20.0f : maxRowHeight;
            
            if (cell.textView)
                [cell.textView removeFromSuperview];
            else
                cell.textView = [[UITextView alloc] initWithFrame:(CGRect){0.0f, 0.0f, 250.0f, maxRowHeight}];
            [cell.textView setDelegate:cell];
            [cell.textView setBackgroundColor:[UIColor clearColor]];
            
            [cell.textView setTextAlignment:NSTextAlignmentLeft];
            [cell.textView setUserInteractionEnabled:YES];
            [cell.textView setReturnKeyType:UIReturnKeyDefault];
            
            [cell.detailTextLabel setText:formatted];
            [cell.textView setEditable:editable];

            if (editable) {
                keyboardType = [[rowDictionary valueForKey:@"kbType"] integerValue];
                [cell.textView setKeyboardType:keyboardType];
                if (capitalized)
                    [cell.textView setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                else
                    [cell.textView setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
                if (autocorrect)
                    [cell.textView setAutocorrectionType:UITextAutocorrectionTypeYes];
                else
                    [cell.textView setAutocorrectionType:UITextAutocorrectionTypeNo];
            }

            break;
            
        case SPTypeSimpleList:
            
            // Expand the list provided as an array in the value field. Mark the current choice
            // as selected if it atches the currently seting in the valueIn dictionary.
            
            [cell.textLabel setText:[[choices objectAtIndex:indexPath.row] valueForKey:@"name"]];
            selectionStyle = UITableViewCellSelectionStyleDefault;
            NSInteger selectedRow = [[[choices objectAtIndex:indexPath.row] valueForKey:@"value"] integerValue];
            if ([(NSNumber *)value integerValue] == selectedRow) {
                accessoryType = UITableViewCellAccessoryCheckmark;
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            break;
            
        case SPTypeChoice:
            
            // Mark the current choice as selected and add a checkmark if the current indexPath
            // matches the valueIn setting.
            
            selectionStyle = UITableViewCellSelectionStyleDefault;
            if ([(NSNumber *)value integerValue] == [choices integerValue]) {
                accessoryType = UITableViewCellAccessoryCheckmark;
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            break;
            
        case SPTypeMultiValue:
            
            // A multi-value field provides a drop-down list for the selection but at the
            // end it's the value associated with a title in the list that becomes the result
            // (and not the index into that list).
            
            choicesDictionary = [NSDictionary dictionaryWithObjects:[choices valueForKey:@"name"]
                                                            forKeys:[choices valueForKey:@"value"]];
            [cell.detailTextLabel setText:[choicesDictionary objectForKey:value]];
            [cell.textField setEnabled:NO];
            
            if (editable) {
                selectionStyle = UITableViewCellSelectionStyleDefault;
                accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                selectionStyle = UITableViewCellSelectionStyleNone;
                accessoryType = UITableViewCellAccessoryNone;
            }
            break;
            
        case SPTypePList:
            
            // Handle drop down lists and nested property lists here. See the implementation of the
            // multi-level types in the tableView:didSelectRowAtIndexPath: method.
            
            [cell.detailTextLabel setText:[valuesIn valueForKey:identifier]];
            
            selectionStyle = UITableViewCellSelectionStyleDefault;
            accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case SPTypeAction:
            
            // Handle the formatting of cells for actions here. Overlay a button over the entire
            // cell using the contentView. The action is triggered by the button, not by the
            // selected tableview cell.
            
            selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (cell.button) {
                [cell.button removeFromSuperview];
            } else
                cell.button = [UIButton buttonWithType:UIButtonTypeCustom];
            [cell.button setFrame:(CGRect){0.0, 0.0, cell.frame.size.width, self.tableView.rowHeight}];
            for (NSDictionary *state in choices) {
                UIControlState controlState = [[state valueForKey:@"value"] integerValue];
                [cell.button setTitle:[state valueForKey:@"name"] forState:controlState];
                switch (controlState) {
                    case UIControlStateDisabled:
                        [cell.button setTitleColor:[UIColor lightGrayColor] forState:controlState];
                        [cell.button setEnabled:NO];
                        break;
                    case UIControlStateSelected:
                        [cell.button setTitleColor:[UIColor blueColor] forState:controlState];
                        [cell.button setSelected:YES];
                        break;
                    case UIControlStateHighlighted:
                        [cell.button setHighlighted:YES];
                    case UIControlStateApplication:
                        [cell.button setTitleColor:[UIColor redColor] forState:controlState];
                        break;
                    default:
                        [cell.button setTitleColor:[UIColor blueColor] forState:controlState];
                        break;
                }
            }
            
            // Set initial state of button.
            UIControlState initialState = [value integerValue];
            switch (initialState) {
                case UIControlStateNormal:
                    [cell.button setEnabled:YES];
                    [cell.button setSelected:NO];
                    [cell.button setHighlighted:NO];
                    break;
                case UIControlStateDisabled:
                    [cell.button setEnabled:NO];
                    [cell.button setSelected:NO];
                    break;
                case UIControlStateSelected:
                    [cell.button setEnabled:YES];
                    [cell.button setSelected:YES];
                    break;
                case UIControlStateHighlighted:
                    [cell.button setHighlighted:YES];
                case UIControlStateApplication:
                    break;
                default:
                    break;
            }
            
            [cell.button setBackgroundColor:[UIColor whiteColor]];
            [cell.button addTarget:cell action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:cell.button];
            [cell.textLabel setHidden:YES];
            break;
            
        default:
            break;
    }
    
    [cell setSelectionStyle:selectionStyle];
    [cell setAccessoryType:accessoryType];
    if (accessoryView)
        [cell setAccessoryView:accessoryView];
    else
        [cell setAccessoryView:nil];
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // We use this callback to add a checkbox to a selected choice of a multi-value property.
    // Only invoke the didChange method if the selected row is different from the previously
    // selected one.
    
    NSDictionary *rowDictionary = [self rowForIndexPath:indexPath];
    SettingsPropertyType type = (SettingsPropertyType)[[rowDictionary valueForKey:@"type"] integerValue];
    BOOL editable = [[rowDictionary valueForKey:@"edit"] boolValue];
    
    NSIndexPath *oldIndex = [self.tableView indexPathForSelectedRow];
    
    if (![oldIndex isEqual:indexPath]) {
        
        NSString *identifier = [rowDictionary valueForKey:@"identifier"];
        NSObject *value = [rowDictionary valueForKey:@"value"];
        
        switch (type) {
            case SPTypeSimpleList:
                // Only allow selection of row when simple list is editable.
                if (editable) {
                    [self.tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
                    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                    [self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
                    [self didChange:[[(NSArray *)value objectAtIndex:indexPath.row] valueForKey:@"value"] forKey:identifier];
                }
                break;
                
            case SPTypeChoice:
                // Only allow selection of row when multi-value list is editable.
                if (editable) {
                    [self.tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
                    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                    [self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
                    [self didChange:value forKey:identifier];
                }
                break;
                
            default:
                break;
        }
    }
    
    return indexPath;
}

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the row definition
    // NSDictionary *section = [pList objectAtIndex:indexPath.section];
    // NSDictionary *rowDictionary = [[section valueForKey:@"rows"] objectAtIndex:indexPath.row];
    NSDictionary *rowDictionary = [self rowForIndexPath:indexPath];
    NSMutableArray *rows;
    
    NSInteger type = [[rowDictionary valueForKey:@"type"] integerValue];
    NSString *identifier = [rowDictionary valueForKey:@"identifier"];
    NSObject *value = [rowDictionary valueForKey:@"value"];
    BOOL editable = [[rowDictionary valueForKey:@"edit"] boolValue];
    
    switch (type) {
            
        case SPTypeSimpleList:
        case SPTypeChoice:
            
            // Both types are primarily handled in the tableView:willSelectRowAtIndexPath: method.
            //[self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
            
            break;
            
        case SPTypeMultiValue:
            
            // The property is a multi-value field for which the next level of the SettingsViewController is
            // used to display the choices. We have to wrap the array of choices in an envelope so that it can
            // be handled consistently on the next level.
            // The envelope consists of one section titled "Envelope" plus as many rows as there are choices.
            // We reuse the SettingsViewController class again to display the choices in a grouped style tableview
            // on the next level down. The envelope section will not be displayed and is titleless instead. Note
            // that the multi-level type becomes a <SPTypeChoice> on the row level in the pushed viewcontroller.
            
            if (editable) {
                rows = [[NSMutableArray alloc] initWithCapacity:[(NSArray *)value count]];
                for (NSDictionary *row in (NSArray *)value)
                    [rows addObject: P_ROW([row valueForKey:@"name"], SPTypeChoice, [row valueForKey:@"value"], editable, UIKeyboardTypeDefault, @"", identifier)];
                
                // This will become the new property list on the next lower level.
                value = @[
                          @{@"title": @"Envelope", @"type": @(SPTypeMultiValue), @"rows": rows }
                          ];
            } else
                break;
            
            // Break omitted intentially here to share code with the property list type unless the multi-value
            // list is not editable. In that case we don't need to push the SettingsViewController as we don't want
            // to offer a choice.
            
        case SPTypePList:
            
            // Type is a property (or enveloped multi-value) list - we call the SettingsViewController recursively.
            // The instance is created dynamically here and will be deallocated when viewcontroller is popped
            // by the use of the back button.
            
            if (!settingsViewController) {
                settingsViewController = [[SettingsViewController alloc] initWithProperties:(NSArray *)value];
                [settingsViewController setNestingLevel:nestingLevel + 1];
                [settingsViewController setDelegate:delegate];
            }
            [settingsViewController setTitle:[rowDictionary valueForKey:@"name"]];
            [settingsViewController setValuesIn:self.valuesIn];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
            
        case SPTypeAction:
            
            // Property is of type action, i.e. a callback to be invoked with the full set of current property values
            // as parameters. The method must be provided as a selector cast into a string and must be implemented
            // by the SettingsViewController Delegate.
            
            break;
            
        default:
            break;
    }
    return;
}

@end


@implementation SettingsViewCell

@synthesize textField, textView, webView, rowDictionary, viewController, button;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialize cell
        
        // Add a textField for the parameter display and editing.
        textField = [[UITextField alloc] initWithFrame:(CGRect){0.0f, 0.0f, 250.0f, 20.0f}];
        [textField setDelegate:self];
        [textField setBackgroundColor:[UIColor clearColor]];
        
        [textField setTextAlignment:NSTextAlignmentLeft];
        [textField setUserInteractionEnabled:YES];
        [textField setReturnKeyType:UIReturnKeyDone];
    }
    
    textView = nil;
    
    return self;
}

- (void)layoutSubviews {
    
    // Let the labels size themselves to accommodate their text
    [super layoutSubviews];
    // NSLog(@"Cell(%i) name(%@)", self.tag, [rowDictionary valueForKey:@"identifier"]);
    
    [self.textLabel sizeToFit];
    [self.detailTextLabel sizeToFit];
    CGRect textFrame, detailFrame = self.detailTextLabel.frame;
    CGFloat offset = -20.0f;
    
    NSString *htmlString;
    NSAttributedString *attributedString;
    NSData *data;
    NSError *error;

    // We need to reset some cell type specific view in order to avoid confusion.
    [self.textField removeFromSuperview];
    [self.textView removeFromSuperview];
    
    // To align settings values nicely we use kind of tabs. A text label should start at
    // one of the tab stops.
    
    NSInteger tabs = 40, indent = (NSInteger) self.textLabel.frame.size.width;
    indent = tabs * (2 + indent / tabs);
    
    // Adjust textField for input.
    SettingsPropertyType type = (SettingsPropertyType)[[rowDictionary valueForKey:@"type"] integerValue];
    switch (type) {
        case SPTypeString:
            
            // String properties are left justified. We need to trick the tableView cell here as
            // the UITableViewCellStyleValue1 style has the detailTextLabel right justified but we
            // want it to be left justified.
            
            textFrame = (CGRect){indent, detailFrame.origin.y,
                self.contentView.frame.size.width - indent - 50.0f, detailFrame.size.height};
            [self.textField setText:self.detailTextLabel.text];
            [self.textField setFont:[UIFont systemFontOfSize:self.detailTextLabel.font.pointSize]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.textField setFrame:textFrame];
            [self.contentView addSubview:textField];
            [self.textLabel setHidden:NO];
            [self.detailTextLabel setHidden:YES];
            
            break;
            
        case SPTypeMultilineText:

            // A multi-line textView extends over the enire row and hides the text label. We take
            // the textLabel x-origin for the textView's origin. The height is given by the cell's
            // height which has been properly calculated in the tableView:heightForRowAtIndexPath:
            // delegate method.

            detailFrame = self.textLabel.frame;
            textFrame = (CGRect){detailFrame.origin.x, 0.0f,
                self.contentView.frame.size.width - detailFrame.origin.x, self.frame.size.height};
            [self.textView setText:self.detailTextLabel.text];
            [self.textView setFont:[UIFont systemFontOfSize:self.detailTextLabel.font.pointSize]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.textView setFrame:textFrame];
            [self.contentView addSubview:textView];
            [self.textLabel setHidden:YES];
            [self.detailTextLabel setHidden:YES];
            
            break;
            
        case SPTypeHTML:
            
            // A HTML webView extends over the enire row and hides the text label. We take
            // the textLabel x-origin for the textView's origin. The height is given by the cell's
            // height which has been properly calculated in the tableView:heightForRowAtIndexPath:
            // delegate method.
            
            detailFrame = self.textLabel.frame;
            textFrame = (CGRect){detailFrame.origin.x, 0.0f,
                self.contentView.frame.size.width - detailFrame.origin.x, self.frame.size.height};

            // Turn the HTML string into an attributedString for the textView.
            htmlString = [NSString stringWithFormat:@"<pre>%@</pre>", self.detailTextLabel.text];
            data = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
            attributedString = [[NSAttributedString alloc] initWithData:data
                                                            options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                       NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                                                                       }
                                                     documentAttributes:nil
                                                                  error:&error];
            textView.attributedText = attributedString;
            [textView setFont:[UIFont fontWithName:@"Courier New" size:14.0]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.textView setFrame:textFrame];
            [self.contentView addSubview:textView];
            [self.textLabel setHidden:YES];
            [self.detailTextLabel setHidden:YES];
            
            break;
            
        case SPTypeMultiValue:
            
            // Multi-value properties cannot be changed on this level and so the current value is
            // informative and ddisplayed right justified.
            
            textFrame = (CGRect){detailFrame.origin.x + offset, detailFrame.origin.y,
                detailFrame.size.width -= offset, detailFrame.size.height};
            [self.textField setText:self.detailTextLabel.text];
            [self.textField setFont:[UIFont systemFontOfSize:self.detailTextLabel.font.pointSize]];
            [self.textField setTextColor:[UIColor lightGrayColor]];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.textField setFrame:textFrame];
            [self.contentView addSubview:textField];
            [self.textLabel setHidden:NO];
            [self.detailTextLabel setHidden:YES];
            
            break;
        default:
            
            [self.detailTextLabel setHidden:NO];
            [self.textLabel setHidden:NO];

            break;
    }
}

- (void)switchOnOff:(id)sender {
    
    // This method implements the Boolean property type. The callback triggered by the user touching the switch.
    // The status is read from the switch and both values dictionaries are updated.
    
    UISwitch *onOffSwitch = (UISwitch *)self.accessoryView;
    [viewController didChange:@(onOffSwitch.on) forKey:[self.rowDictionary valueForKey:@"identifier"]];
}

- (void)buttonSelected:(id)sender {
    
    // Method triggered by a selected button for an action type property. This method
    // invokes the user defined callback for the property.
    
    NSString *selector = [self.rowDictionary valueForKey:@"flags"];
    NSString *value = [self.rowDictionary valueForKey:@"identifier"];
    
    // Since we want the callback to return the UIControlState of the button we need to use NSInvocation
    // class to capture the return value.
    
    if (value) {
        SEL action = NSSelectorFromString(selector);
        
        UIControlState controlState;
        if ([viewController.delegate respondsToSelector:action]) {
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                        [[viewController.delegate class] instanceMethodSignatureForSelector:action]];
            [invocation setSelector:action];
            [invocation setTarget:viewController.delegate];
            [invocation setArgument:&sender atIndex:2];
            [invocation invoke];
            [invocation getReturnValue:&controlState];
            
            switch (controlState) {
                    
                case UIControlStateDisabled:
                    [self.button setEnabled:NO];
                    break;
                case UIControlStateSelected:
                    [self.button setEnabled:YES];
                    [self.button setSelected:YES];
                    break;
                case UIControlStateHighlighted:
                    [self.button setEnabled:YES];
                    [self.button setHighlighted:YES];
                    break;
                case UIControlStateApplication:
                    [self.button setEnabled:YES];
                    [self.button setHighlighted:YES];
                    break;
                default:
                    [self.button setEnabled:YES];
                    [self.button setSelected:NO];
                    [self.button setHighlighted:NO];
                    break;
            }
        }
    }
    viewController.valuesIn = [viewController mergeValues:viewController.valuesOut];
}

- (void)textFieldDidEndEditing:(UITextField *)aTextField {
    
    // Dismiss keyboard, give up first responder capability. Then read the string and update both values dictionaries.
    // Triggered when the user ends editing by jumping to the next property.
    
    [aTextField resignFirstResponder];
    [viewController didChange:aTextField.text forKey:[self.rowDictionary valueForKey:@"identifier"]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)aTextField {
    
    // Dismiss keyboard, give up first responder capability. Triggered when the user hits return on the keyboard.
    [aTextField resignFirstResponder];
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView {
    
    // Dismiss keyboard, give up first responder capability. Triggered when the user hits return on the keyboard.
    [aTextView resignFirstResponder];
    [viewController didChange:aTextView.text forKey:[self.rowDictionary valueForKey:@"identifier"]];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
    
    [viewController didChange:aTextView.text forKey:[self.rowDictionary valueForKey:@"identifier"]];
}

@end
