//
//  SettingsViewController.m
//  ChefsHand
//
//  Created by Andreas Werder on 1/12/14.
//  Copyright (c) 2014, 2015 Material Apps. All rights reserved.
//
//  Changes history:
//  2014-01-12  Initial implementation - totally property list driven
//  2014-01-26  Added implementation of settings type Action (button)
//  2014-01-27  Added implementation of settings type simple list
//  2014-03-03  Added implementation of settings type multi-line text view
//  2014-03-09  Added implementation of settings type HTML text view
//  2014-09-01  Fixed an issue with inputViewController property for cell with iOS 8
//  2014-12-16  Added editing capability for integer type properties
//  2015-01-01  Added picker list type and section key for lookups in PList type sub-settings
//  2015-01-02  Added default value for picker list
//  2015-01-04  Row dictionary available in didChange:forRow:; propertiesForRow: now a delegate method
//  2015-02-01  Renamed propertiesForRow and added willChange/didChangePropertiesForRow
//  2015-02-18  Changing properties with didChange:forRow: updates the detailLabel text
//  2015-05-23  Made first row of picker list editable to add new distinct values
//  2015-08-09  Added dynamic update of property lists after additions and deletions
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
//  - Integer           A simple short or long integer for presentation and editing.
//  - Decimal           Decimal number, for presentation and editing.
//  - Date              A full date/time stamp, presentation only (editing not supported).
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
//  - Custom            Read-only property that is displayed using the provided callbacks
//                      that determine height and cell context for presentation. Note that
//                      custom properties can be deleted by swiping the cell.
//
//  Multi-level types:  Invoke the SettingsViewController recursively for as many levels
//                      as required.
//
//  - Multi-value       Provides a drop-down list like interface using a second level
//                      of the SettingsViewController. The multi-value type is based on
//                      a title-value tuple per choice. The controller displays the title
//                      but the result returned is given by the corresponding value for
//                      the title.
//  - Picker List       Similar to the multi-value option, a Picker List allows the selection
//                      of a specific value from a list but through the Picker metaphor.
//                      Providing a default value will result in a simple list for which
//                      the user can select either the default or the picker value. 
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
//                      Required callback used to provide a dictionary of name/value tuples
//                      to be used as initial values in the propery lists. The names of the
//                      values presented must match the identifier provided for the particular
//                      property.
//
//  -willChangePropertiesForRow:rowDictionary:
//                      Optional callback that implements the dynamic composition of recursive
//                      Property lists. The method is called every time a property list is being
//                      built dynamically. To take correct action the rowDictionary parameter
//                      must be checked for instance for the IDENTIFIER.
//  -didChangePropertiesForRow:rowDictionary:
//                      Optional callback that is called when a previous willChangePropertiesForRow
//                      has created a new Property list. To take correct action the rowDictionary
//                      parameter must be checked for instance for the IDENTIFIER.
//  -refreshPropertiesList:
//                      Optional callback that must return an updated property list. If no updates
//                      are posted then the callback must return the existing property list.
//
//  -settingsDefault:sender:
//                      Optional callback similar to the settingsInput method which is used to
//                      provide default values for properties. The method must return a
//                      dictionary of default name/value pairs.
//
//  -settingsDidChange:forRow:
//                      Optional callback that is invoked in the protocol delegate whenever a
//                      value from the property list has been changed by the user.
//
//  -willDismissModalView:sender:
//                      Callback invoked BEFORE the didDismissModalView is invoked. The callback
//                      can be used to determine if the SettingsViewControlller has to be
//                      dismissed for instance when changes to the properties must be committed.
//
//  -didDismissModalView:sender:
//                      Callback that must implement one of the dismissController methods
//                      used by the UIViewController class to release a controller.
//
//  Delegate Protocol for Custom type properties:
//
//  -customSetting:heightForRowAtIndexPath:
//                      Optional callback that can be used to specifiy the height of a Custom
//                      cell. The indexPath must be used to distinguish between custom cells
//                      if multiple properties are formatted with custom cells.
//
//  -customSetting:cellForRowAtIndexPath:
//                      Optional callback for format a SettingsViewCell. Again, the indexPath
//                      parameter must be used to distinguish between different custom cells
//                      if multiple properties are formatted with custom cells. The method is
//                      similar to the tableView:cellForRowAtIndexPath: method and it must
//                      return a correctly built SettimngsViewCell object. The style of the
//                      cell must be specified by the VALUE parameter of the row dictionary.
//
// - customSetting:commitDeleteForRowAtIndexPath:
//
//
//  Extension for Class SettingsViewCell:
//                      The SettingsViewCell class can be extended in the parent view controller
//                      to add standard functionality for editing properties. To edit multi-line
//                      or HTML text fields, a UITextView field is used which implements the
//                      canPerformAction:withSender: callback to support a context menu.
//                      The extension can be used to overwrite the default behavior.
//


#import "SettingsViewController.h"

// Cell and Title View identifiers
static NSString * const cellIdentifierDefault = @"SettingsViewCellDefault";
static NSString * const cellIdentifierCustom = @"SettingsViewCellCustom";
static NSString * const headerViewIdentifier = @"SectionHeaderView";

// Keys to the various dictionaries.
static NSString * const TITLE = @"title";
static NSString * const KEY = @"key";
static NSString * const HEADER = @"header";
static NSString * const ROWS = @"rows";
static NSString * const FOOTER = @"footer";
static NSString * const NAME = @"name";
static NSString * const TYPE = @"type";
static NSString * const VALUE = @"value";
static NSString * const EDIT = @"edit";
static NSString * const KEYBOARDTYPE = @"kbType";
static NSString * const FLAGS = @"flags";
static NSString * const IDENTIFIER = @"identifier";

@interface SettingsViewController () {
    
    // SettingsViewController *settingsViewController;
    UIMenuController *menuController;
    SettingsPickerView *pickerView;
}

@end


@implementation SettingsViewController

@synthesize delegate, nestingLevel, valuesIn, valuesOut, valuesDefault;
@synthesize menuController, selectedIndexPath;
@synthesize propertyList = _propertyList;
@synthesize rowDictionary = _rowDictionary;
@synthesize settingsViewController;

- (id)init {
    
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
        // Custom initialization
        [self setTitle:@"Settings"];
        nestingLevel = 0;
        valuesOut = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        // Initialize tableView
        [self.tableView setDelegate:self];
        [self.tableView setDataSource:self];
        [self.tableView setAllowsSelection:YES];
        
        // TableView configuration. We register the subclass of UITableViewCell to
        // get a protoype. The cell is initialized in initWithStyle:reuseIdentifier:.
        
        [self.tableView registerClass:[SettingsViewCell class]
               forCellReuseIdentifier:cellIdentifierDefault];
        // [self.tableView registerClass:[SettingsViewCell class] forCellReuseIdentifier:cellIdentifierCustom];
        [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:headerViewIdentifier];
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
            [self.navigationItem setHidesBackButton:YES];
            
            // Now get the settings initial values and the default values; they will be carried in
            // valuesIn and valuesDefault while changed settings are in valuesOut.
            
            valuesIn = [delegate settingsInput:self];
            if ([delegate respondsToSelector:@selector(settingsDefault:)])
                valuesDefault = [delegate settingsDefault:self];
            valuesOut = [[NSMutableDictionary alloc] initWithCapacity:5];
        } else {
            
            // We give the didChangePropertiesForRow delegate protocol method a chance
            // if a corresponding willChangePropertiesForRow has set the _rowDictionary
            // previously. Also refresh the entire property list if we have a delegate
            // method for doing so.
            
            valuesIn = [delegate settingsInput:self];
            if ([delegate respondsToSelector:@selector(settingsDefault:)])
                valuesDefault = [delegate settingsDefault:self];
            valuesOut = [[NSMutableDictionary alloc] initWithCapacity:5];
            if ([delegate respondsToSelector:@selector(didChangePropertiesForRow:)] && _rowDictionary) {
                [delegate didChangePropertiesForRow:_rowDictionary];
            }
            if ([delegate respondsToSelector:@selector(refreshPropertiesList:)]) {
                _propertyList = [delegate refreshPropertiesList:_propertyList];
            }
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

- (void)dismissViewController {

    // A simple interface method to dismiss the controller from outside.
    [self dismissView:nil];
}

- (void)setPropertiesForRow:(NSDictionary *)row {
    
    // Get the properties from the delegate protocol method willChangePropertiesForRow
    // if it exists. We also set the _rowDictionary private property so that we can use
    // it in a subsequent didChangePropertiesForRow call.
    
    _rowDictionary = row;
    _propertyList = [delegate willChangePropertiesForRow:row];
}

#pragma mark - SettingsViewController internal methods that invoke delegate protocol methods

- (void)didChange:(id)value forRow:(NSDictionary *)row {
    
    // Captures a changed value and updates the valueOut mutable dictionary. It also
    // re-builds the valueIn dictionary. When completed it then gives the protocol delegate
    // a chance to take action.
    // Only change the value if it is different from the previous generation.
    
    // Note that the didChange:forRow should always be invoked under the top SetttingsViewController.
    // If this is not the case we call this method recursively under the proper view controller.

    SettingsViewController *topViewController = (SettingsViewController *)[[self navigationController]
                                                                           topViewController];
    if (self != topViewController) {
        [topViewController didChange:value forRow:row];
    } else {
        if (![value isEqual:[valuesIn valueForKey:row[IDENTIFIER]]]) {
            NSDictionary *dictionary = [NSDictionary dictionaryWithObject:value forKey:row[IDENTIFIER]];
            [valuesOut addEntriesFromDictionary:dictionary];
            valuesIn = [self mergeValues:valuesOut];
            
            // Invoke protocol delegate method if defined.
            if ([delegate respondsToSelector:@selector(settingsDidChange:forRow:)])
                [delegate performSelector:@selector(settingsDidChange:forRow:) withObject:value withObject:row];
            
            // Now locate the cell with the detailTextLabel value that changed and update it.
            // We could end up having several cells with the same IDENTIFIER so we need to loop
            // through the list of visible cells in the top view controller's tableview. We do not
            // bother to update the value if the type is a boolean (switch) or multiline text.
            
            if ([row[TYPE] shortValue] != SPTypeBoolean && [row[TYPE] shortValue] != SPTypeMultilineText) {
                [[self.tableView visibleCells] enumerateObjectsUsingBlock:^(SettingsViewCell *cell, NSUInteger idx, BOOL *stop) {
                    
                    if (cell.tag == [row[IDENTIFIER] hash] && (SettingsPropertyType)[row[TYPE] integerValue] != SPTypePickerView) {
                        if ([self primitiveType:value] == 0)
                            [cell.detailTextLabel setText:value];
                        else
                            // [cell.detailTextLabel setText:[value stringValue]];
                            [cell.detailTextLabel setText:@""];
                        // Don't forget to refresh the cell display.
                        [self.tableView reloadRowsAtIndexPaths:@[[self.tableView indexPathForCell:cell]]
                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];

                // Invoke protocol delegate method for refreshing the property list and
                // reload the tableview data.
                
                if ([delegate respondsToSelector:@selector(refreshPropertiesList:)]) {
                    _propertyList = [delegate refreshPropertiesList:_propertyList];
                    [self.tableView reloadData];
                }
            }
        }
    }
}

- (void)didChange:(id)value forKey:(NSString *)name {
    
    // Same method as didChange:forRow but instead of the row dictionary only the
    // IDENTIFIER (name) has to be provided. This method is a more bit straightforward
    // and we'll leave it for compatibility reasons with earlier Settings VC releases.
    
    if (![value isEqual:[valuesIn valueForKey:name]]) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObject:value forKey:name];
        [valuesOut addEntriesFromDictionary:dictionary];
        valuesIn = [self mergeValues:valuesOut];	
        
        // Invoke protocol delegate method if defined. Note that we need a row dictionary
        // but since we don't have it at this point we construct a down-stripped dictionary
        // with just the value and the identifier (name).
        
        if ([delegate respondsToSelector:@selector(settingsDidChange:forRow:)]) {
            NSDictionary *rowDictionary = @{VALUE: value, IDENTIFIER: name};
            [delegate performSelector:@selector(settingsDidChange:forRow:) withObject:value withObject:rowDictionary];
        }
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

- (NSDictionary *)rowDictionary:(NSIndexPath *)indexPath {
    
    // Unpublished method that retrieves the row dictionary for a given indexPath.
    NSDictionary *section = [_propertyList objectAtIndex:indexPath.section];
    return [[section valueForKey:ROWS] objectAtIndex:indexPath.row];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return [_propertyList count];
}

- (NSDictionary *)rowForIndexPath:(NSIndexPath *)indexPath {
    
    // Auxiliary method to select the rows based on indexPath and type.
    NSArray *sectionArray = [_propertyList objectAtIndex:indexPath.section];
    NSArray *rows = [sectionArray valueForKey:ROWS];
    NSDictionary *firstRow = [rows firstObject];
    
    if ([[firstRow valueForKey:TYPE] integerValue] == SPTypeSimpleList)
        return firstRow;
    else
        return [rows objectAtIndex:indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger numberOfRows = 0;
    NSDictionary *sectionArray = [_propertyList objectAtIndex:section];
    NSArray *rows = sectionArray[ROWS];
    numberOfRows = [rows count];
    
    // We need to handle special case here of a simple list. Anything else is standard.
    // Note that thre is a restriction that when a simple list is used the section must
    // only contain ONE row.
    
    if (numberOfRows == 1 && [[[rows firstObject] valueForKey:TYPE] integerValue] == SPTypeSimpleList) {
        NSArray *choices = [[rows valueForKey:VALUE] firstObject];
        numberOfRows = [choices count];
    }

    return numberOfRows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the row definition
    BOOL canEdit = NO;
    
    NSDictionary *section = [_propertyList objectAtIndex:indexPath.section];
    NSArray *rows = [section valueForKey:ROWS];
    
    if ([[[rows objectAtIndex:indexPath.row] valueForKey:TYPE] shortValue] == SPTypeCustom) {
        canEdit = YES;
    } else
        canEdit = NO;
    
    return canEdit;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *section = [_propertyList objectAtIndex:indexPath.section];
    NSArray *rows = [section valueForKey:ROWS];
    
    // If we have a type unequal to SPTypeSimpleList then we can take the edit flag from
    // the row. Simple lists cannot be edited, so we return a NO for those.
    
    if ([[[rows firstObject] valueForKey:TYPE] integerValue] != SPTypeSimpleList) {
        if ([delegate respondsToSelector:@selector(customSetting:commitDeleteForRowAtIndexPath:)]) {
            [delegate performSelector:@selector(customSetting:commitDeleteForRowAtIndexPath:)
                           withObject:self
                           withObject:indexPath];
            if ([delegate respondsToSelector:@selector(refreshPropertiesList:)]) {
                _propertyList = [delegate refreshPropertiesList:_propertyList];
                [self.tableView reloadData];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat rowHeight = UITableViewAutomaticDimension;
    NSDictionary *section = [_propertyList objectAtIndex:indexPath.section];
    NSArray *rows = [section valueForKey:ROWS];
    NSString *detailText;
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    // We first need to check if this is a simple list to avoid index out of range error; then
    // we check if we have a multi-line text view. If so, we take a height large enough for a bunch
    // of lines.
    
    if ([[rows firstObject][TYPE] integerValue] != SPTypeSimpleList) {
        NSDictionary *row = [rows objectAtIndex:indexPath.row];
        SettingsPropertyType type = (SettingsPropertyType)[[row valueForKey:TYPE] integerValue];
        
        switch (type) {
                
            case SPTypeCustom:
                // Get the row height from the delegate protocol method.
                if ([delegate respondsToSelector:@selector(customSetting:heightForRowAtIndexPath:)])
                    rowHeight = [delegate customSetting:self heightForRowAtIndexPath:indexPath];
                break;
                
            case SPTypeHTML:
                font = [UIFont fontWithName:@"Courier New" size:16.0];
                // A break; statement is intentionally omitted here to share the code with the default case.
                
            default:
                
                // Calculate the row height for all other cases.
                if (type == SPTypeMultilineText || type == SPTypeHTML) {
                    id tmp = [valuesIn valueForKey:[row valueForKey:IDENTIFIER]];
                    if ([NSStringFromClass([tmp class]) isEqualToString:@"NSNull"])
                        detailText = @"";
                    detailText = [NSString stringWithFormat:@"%@", tmp];
                    BOOL editMode = [[row valueForKey:EDIT] boolValue];
                    
                    CGSize maximumLabelSize = CGSizeMake(tableView.frame.size.width * 0.8, CGFLOAT_MAX);
                    CGRect frame = [detailText boundingRectWithSize:maximumLabelSize
                                                            options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                         attributes:@{NSFontAttributeName: font}
                                                            context:nil];
                    // We give quite a bit of empty space initially and also add 3 to 4 empty lines if in edit mode.
                    rowHeight = ([detailText length] == 0) ? MAX(250.0, frame.size.height) : MAX(40.0, frame.size.height) + editMode * 32.0f;
                    break;
                }
        }
    }
    return rowHeight;
}

#pragma mark - Table view header and footer view definitions

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    // We display the section title for all types of properties except a multi-value list
    // in an envelope where we don't want to display the synthetic envelope layer.
    
    NSString *title;
    SettingsPropertyType type = (SettingsPropertyType)[[[_propertyList objectAtIndex:section] valueForKey:TYPE] integerValue];
    if (type != SPTypeMultiValue && type != SPTypePickerList)
        title = [[_propertyList objectAtIndex:section] valueForKey:@"title"];
    else
        title = @"";
    
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    // The tableView:heightForHeaderInSection: delegate method must be present so that
    // the tableView:viewForHeaderInSection: is called. 

    CGFloat headerHeight = UITableViewAutomaticDimension;
    SettingsPropertyType type = (SettingsPropertyType)[[[_propertyList objectAtIndex:section] valueForKey:TYPE] integerValue];
    NSString *header = [[_propertyList objectAtIndex:section] valueForKey:@"header"];
    
    if (type != SPTypeMultiValue && type != SPTypePickerList && ![header isEqual:[NSNull null]]) {
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
    
    SettingsPropertyType type = (SettingsPropertyType)[[[_propertyList objectAtIndex:section] valueForKey:TYPE] integerValue];
    sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewIdentifier];
    
    if (type != SPTypeMultiValue) {
        title = [[_propertyList objectAtIndex:section] valueForKey:@"title"];
        header = [[_propertyList objectAtIndex:section] valueForKey:@"header"];
    } else {
        title = @"";
        header = [[_propertyList objectAtIndex:section] valueForKey:@"header"];
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
    SettingsPropertyType type = (SettingsPropertyType)[[[_propertyList objectAtIndex:section] valueForKey:TYPE] integerValue];
    NSString *footer = [[_propertyList objectAtIndex:section] valueForKey:@"footer"];
    
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
    
    NSString *footer = [[_propertyList objectAtIndex:section] valueForKey:@"footer"];
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
    
    // Get the row definition before anything else. take the row using indexPath into rows
    // when not SPTypeSimpleList.
    
    NSDictionary *rowDictionary = [self rowForIndexPath:indexPath];
    SettingsPropertyType type = (SettingsPropertyType)[rowDictionary[TYPE] integerValue];
    // SettingsPickerView *pickerView;
    
    // We have registered the class so this always gives us a valid cell. Choose either default or
    // then custom type depending on Settings type.
    
    SettingsViewCell *cell;
    if (type == SPTypeCustom) {
        
        // Handle custom cell initialization here.
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierCustom];
        if (!cell)
            cell = [[SettingsViewCell alloc] initWithStyle:[rowDictionary[VALUE] integerValue]
                                           reuseIdentifier:cellIdentifierCustom];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierDefault
                                               forIndexPath:indexPath];
        [cell.textLabel setText:rowDictionary[NAME]];
    }
    
    // Configure the cell.
    [cell setViewController:self];
    [cell setTag:[rowDictionary[IDENTIFIER] hash]];
    [cell setRowDictionary:rowDictionary];

    UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
    UITableViewCellSelectionStyle selectionStyle = UITableViewCellSelectionStyleNone;
    UIKeyboardType keyboardType = UIKeyboardTypeAlphabet;
    UISwitch *accessoryView;
    CGFloat maxRowHeight = 400.0f;
    NSDictionary *choicesDictionary;
    NSString *formatted;
    NSDateFormatter *dateFormatter;
    
    // Clean up the cell from: remove textView and button if we had some from previous runs.
    if (type != SPTypeMultilineText && type != SPTypeHTML)
        if (cell.textView)
            [cell.textView removeFromSuperview];
    if (type != SPTypeAction)
        if (cell.button)
            [cell.button removeFromSuperview];

    // Get flags for the editing and keyboard properties of the detail text label.
    BOOL editable = [rowDictionary[EDIT] boolValue];
    NSString *flags = rowDictionary[FLAGS];
    BOOL capitalized = NSNotFound != [flags rangeOfCharacterFromSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"c"]].location;
    BOOL autoCorrect = NSNotFound != [flags rangeOfCharacterFromSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"a"]].location;
    BOOL secure = NSNotFound != [flags rangeOfCharacterFromSet:
                                 [NSCharacterSet characterSetWithCharactersInString:@"s"]].location;
    BOOL detectLinks = NSNotFound != [flags rangeOfCharacterFromSet:
                                      [NSCharacterSet characterSetWithCharactersInString:@"k"]].location;
    [cell.detailTextLabel setTextColor:[UIColor blackColor]];
    
    // Extract the value for the key from the property list dictionary - if there is one.
    id value, choices;
    NSString *identifier = rowDictionary[IDENTIFIER];
    if (identifier)
        value = [valuesIn valueForKey:identifier];
    choices = rowDictionary[VALUE];
    
    switch (type) {
        case SPTypeString:
            
            // We have a string - display it. But first, set keyboard type and secure
            // text attributes if required.
            
            if (editable) {
                keyboardType = [rowDictionary[KEYBOARDTYPE] integerValue];
                [cell.textField setKeyboardType:keyboardType];
                if (capitalized)
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                else
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                if (autoCorrect)
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
            if (detectLinks) {
                [cell.textView setDataDetectorTypes:UIDataDetectorTypeLink];
                [cell.textView setSelectable:YES];
            }
            break;
            
        case SPTypeInteger32:

            // Format an integer into a string
            [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"%ld", (long)[(NSNumber *)value integerValue]]];

            if (editable) {
                [cell.textField setKeyboardType:UIKeyboardTypeDecimalPad];
                [cell.textField setSecureTextEntry:NO];
                [cell.textField setEnabled:editable];
            }
            break;
            
        case SPTypeDecimal:
            
            // Format a number into a string; use the flags parameter for the formatting.
            // If no format has been specified then use the default string representation.
            
            [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [cell.detailTextLabel setText:([flags length] == 0) ?
                                                                [value stringValue] :
                                                                [NSString stringWithFormat:flags, [value floatValue]]];
            if (editable) {
                [cell.textField setKeyboardType:UIKeyboardTypeDecimalPad];
                [cell.textField setSecureTextEntry:NO];
                [cell.textField setEnabled:editable];
            }
            break;
            
        case SPTypeDate:
            
            // Format a complete date and time value into a string. At the moment we do
            // not allow the date value to be edited.
            
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"YYYY-MMM-dd HH:mm"];
            [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [cell.detailTextLabel setText:[dateFormatter stringFromDate:value]];
            
            [cell.textField setSecureTextEntry:NO];
            [cell.textField setEnabled:NO];
            break;
            
        case SPTypeBoolean:
            
            // The boolean type is implemented with the On/Off switch - just like in the
            // Settings app.
            
            accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
            [accessoryView setOn:[value boolValue]];
            [accessoryView addTarget:cell action:@selector(switchOnOff:)
                    forControlEvents:UIControlEventValueChanged];
            [accessoryView setEnabled:editable];
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
                cell.textView = [[SettingsTextView alloc] initWithFrame:(CGRect){0.0f, 0.0f, 250.0f, maxRowHeight}];
            [cell.textView setDelegate:cell];
            [cell.textView setBackgroundColor:[UIColor clearColor]];
            
            [cell.textView setTextAlignment:NSTextAlignmentLeft];
            [cell.textView setUserInteractionEnabled:YES];
            [cell.textView setReturnKeyType:UIReturnKeyDefault];
            
            [cell.detailTextLabel setText:formatted];
            [cell.textView setEditable:editable];
            if (detectLinks) {
                [cell.textView setDataDetectorTypes:UIDataDetectorTypeLink];
                [cell.textView setSelectable:YES];
            }

            if (editable) {
                keyboardType = [rowDictionary[KEYBOARDTYPE] integerValue];
                [cell.textView setKeyboardType:keyboardType];
                if (capitalized)
                    [cell.textView setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                else
                    [cell.textView setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
                if (autoCorrect)
                    [cell.textView setAutocorrectionType:UITextAutocorrectionTypeYes];
                else
                    [cell.textView setAutocorrectionType:UITextAutocorrectionTypeNo];
            }

            break;
            
        case SPTypeSimpleList:
            
            // Expand the list provided as an array in the value field. Mark the current choice
            // as selected if it atches the currently seting in the valueIn dictionary.
            
            [cell.textLabel setText:[[choices objectAtIndex:indexPath.row] valueForKey:NAME]];
            selectionStyle = UITableViewCellSelectionStyleDefault;
            NSInteger selectedRow = [[[choices objectAtIndex:indexPath.row] valueForKey:VALUE] integerValue];
            if ([(NSNumber *)value integerValue] == selectedRow) {
                accessoryType = UITableViewCellAccessoryCheckmark;
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            break;
            
        case SPTypePickerList:
            
            // A picker field provides a list for the selection. The result is the value associated
            // with a title (name) in the list that becomes the result (and not the index into
            // that list).
            
        case SPTypeMultiValue:
            
            // A multi-value field provides a drop-down list for the selection but at the
            // end it's the value associated with a title (name) in the list that becomes the
            // result (and not the index into that list).
            
            choicesDictionary = [NSDictionary dictionaryWithObjects:[choices valueForKey:NAME]
                                                            forKeys:[choices valueForKey:VALUE]];
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
            
            if ([[identifier componentsSeparatedByString:@"."] count] == 1) {
                NSObject *value = valuesIn[identifier];
                if ([self primitiveType:value] == 0)
                    [cell.detailTextLabel setText:(NSString *)value];
                else
                    // TODO: [cell.detailTextLabel setText:[(NSNumber *)value stringValue]];
                    [cell.detailTextLabel setText:@""];
            } else {
                // Here we handle the lookup of a variable whose lookup dictionary is somewhere deep
                // in the propery sub-list. The way to specifiy such a lookup is through a keypath
                // with the 'identifier' parameter of the type Plist setting (row).
                // It has the form:
                //      <sectionKey>.<rowKey>
                
                NSArray *keyPath = [identifier componentsSeparatedByString:@"."];
                NSAssert([keyPath count] > 1, @"Keypath %@ for lookup must be of length 2", identifier);
                NSDictionary *subPList = [NSDictionary dictionaryWithObjects:choices forKeys:[choices valueForKey:@"key"]];
                NSArray *rows = subPList[[keyPath firstObject]][ROWS];
                NSDictionary *rowDictionaries = [NSDictionary dictionaryWithObjects:rows forKeys:[rows valueForKey:IDENTIFIER]];
                NSArray *subChoices = rowDictionaries[[keyPath objectAtIndex:1]][VALUE];
                NSDictionary *lookup = [NSDictionary dictionaryWithObjects:subChoices forKeys:[subChoices valueForKey:VALUE]];
                [cell.detailTextLabel setText:[lookup objectForKey:[valuesIn valueForKey:[keyPath objectAtIndex:1]]][NAME]];
            }

            selectionStyle = UITableViewCellSelectionStyleDefault;
            accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case SPTypeChoice:
            
            // Mark the current choice as selected and add a checkmark if the current indexPath
            // matches the valueIn setting.
            
            selectionStyle = UITableViewCellSelectionStyleDefault;
            if ([(NSNumber *)value integerValue] == [choices integerValue]) {
                accessoryType = UITableViewCellAccessoryCheckmark;
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            if (editable) {
                keyboardType = [rowDictionary[KEYBOARDTYPE] integerValue];
                [cell.textField setKeyboardType:keyboardType];
                if (capitalized)
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                else
                    [cell.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                if (autoCorrect)
                    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeYes];
                else
                    [cell.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
            }
            break;
            
        case SPTypePickerView:

            // Here we handle the pickerview for a multi-value field. We only initialize it once since
            // we pass here every time the picker wheel is stopped.
            
            if (!pickerView) {
                pickerView = [[SettingsPickerView alloc] initWithFrame:(CGRect){0.0f, self.view.frame.size.height / 2,
                    self.view.frame.size.width, self.view.frame.size.height / 2}];
                [pickerView setParentCell:cell];
                [pickerView setChoices:choices];
                [self.view addSubview:pickerView];
                NSUInteger index = [[choices valueForKey:NAME] indexOfObject:[cell.textLabel text]];
                NSAssert(index != NSNotFound, @"Dictionary for value(%@) not found", [cell.textLabel text]);
                [pickerView selectRow:index inComponent:0 animated:YES];
            }

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
            [cell.detailTextLabel setText:@""];
            for (NSDictionary *state in choices) {
                UIControlState controlState = [[state valueForKey:VALUE] integerValue];
                [cell.button setTitle:[state valueForKey:NAME] forState:controlState];
                switch (controlState) {
                    case UIControlStateNormal:
                        [cell.button setTitleColor:[UIColor blueColor] forState:controlState];
                        [cell.button setEnabled:NO];
                        break;
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
                        [cell.button setTitleColor:[UIColor blueColor] forState:controlState];
                        break;
                    case UIControlStateApplication:
                        [cell.button setTitleColor:[UIColor redColor] forState:controlState];
                        break;
                    default:
                        [cell.button setTitleColor:[UIColor blueColor] forState:controlState];
                        break;
                }
            }
            
            // Set initial state of button. Remember that we overload the keyboard type with the
            // initial state for the SPTypeAction type.
            
            // UIControlState initialState = [value integerValue];
            UIControlState initialState = (UIControlState)[rowDictionary[KEYBOARDTYPE] integerValue];
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
                    [cell.button setEnabled:YES];
                    [cell.button setSelected:NO];
                    [cell.button setHighlighted:YES];
                case UIControlStateApplication:
                    break;
                default:
                    break;
            }
            
            [cell.button addTarget:cell action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:cell.button];
            [cell.textLabel setHidden:YES];
            break;
            
        case SPTypeCustom:
            
            // Invoke the delegate method for custom formatting of a cell.
            if ([delegate respondsToSelector:@selector(customSetting:cellForRowAtIndexPath:)])
                cell = [delegate customSetting:cell cellForRowAtIndexPath:indexPath];
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
    selectedIndexPath = indexPath;
    SettingsPropertyType type = (SettingsPropertyType)[rowDictionary[TYPE] integerValue];
    BOOL editable = [rowDictionary[EDIT] boolValue];
    
    NSIndexPath *oldIndex = [self.tableView indexPathForSelectedRow];
    
    if (![oldIndex isEqual:indexPath]) {
        
        NSObject *value = rowDictionary[VALUE];
        
        switch (type) {
            case SPTypeSimpleList:
                // Only allow selection of row when simple list is editable.
                if (editable) {
                    [self.tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
                    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                    [self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
                    [self didChange:[[(NSArray *)value objectAtIndex:indexPath.row] valueForKey:VALUE] forRow:rowDictionary];
                }
                break;
                
            case SPTypeChoice:
                // Only allow selection of row when multi-value list is editable.
                if (editable) {
                    [self.tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
                    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                    [self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
                    [self didChange:value forRow:rowDictionary];
                }
                break;

            case SPTypePickerView:
                
                // Picker view is always editable. When this type is selected we know that either the second row with
                // the current picker value has been chosen or then the row in the picker list.
                
                [self.tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;
                [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                [self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
                [self didChange:[(NSArray *) value firstObject][VALUE] forRow:rowDictionary];
                break;
                
            default:
                break;
        }
    }
    
    return indexPath;
}

- (NSUInteger)primitiveType:(NSObject *)value {
    
    // Get the enumeration index of the class for an object.
    // Class name for primitives is __NSCF + [Number| String| Boolean].
    
    // NSString *primitiveClass = NSStringFromClass([[value copy] class]);
    NSString *primitiveClass = NSStringFromClass([value class]);
    NSArray *primitives = @[@"ConstantString", @"String", @"Boolean", @"Number", @"Float"];
    NSArray *mapping = @[@(0), @(0), @(1), @(2), @(3)];
    NSRange prefix = [primitiveClass rangeOfString:@"__NSCF"];
    NSString *type = [primitiveClass substringWithRange:(NSRange){prefix.length, [primitiveClass length] - prefix.length}];
    NSUInteger index = [primitives indexOfObject:type];
    return (index >= [primitives count]) ? NSNotFound : [[mapping objectAtIndex:index] longValue];
}

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Get the row definition first.
    NSDictionary *rowDictionary = [self rowForIndexPath:indexPath];
    NSMutableArray *rows;
    
    // NSLog(@"Selected row(%ld) name(%@) value(%@)", (long)indexPath.row, rowDictionary[IDENTIFIER], valuesIn[IDENTIFIER]);
    
    NSInteger type = [rowDictionary[TYPE] integerValue];
    NSString *identifier = rowDictionary[IDENTIFIER];
    NSObject *value = rowDictionary[VALUE];
    BOOL editable = [rowDictionary[EDIT] boolValue];
    SettingsPropertyType subType;
    
    switch (type) {
            
        case SPTypeSimpleList:
        case SPTypeChoice:
            
            // All these types are primarily handled in the tableView:willSelectRowAtIndexPath: method.
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
            
        case SPTypePickerList:
            
            // The property is a multi-value field but for the selection we use a more complex structure:
            // 1)   On the next level down we have a simple list with two elements:
            //      - the first row is the default
            //      - the second row is the value that we pick from the UIPickerView
            // 2)   A separate UIPickerView view at the bottom of the SettingsView that is large enough for
            //      handling big picker lists.
            // Note that for the second row we will use an internal type of SPTypePickerView to distinguish
            // the property list from the multi-value type (for which we use the internal type SPTypeChoice).
            
            if (editable) {
                
                NSArray *pickerList;
                NSDictionary *pickerDictionary;
                NSString *initialValue;
                
                subType = (type == SPTypePickerList) ? SPTypePickerView : SPTypeChoice;
                rows = [[NSMutableArray alloc] initWithCapacity:[(NSArray *)value count]];

                // Build the new property list on the next lower level on the fly. We use different
                // lists for the multi-value and the picker list type.

                switch (type) {
                    case SPTypeMultiValue:

                        for (NSDictionary *row in (NSArray *)value)
                            [rows addObject: P_ROW([row valueForKey:NAME], subType, [row valueForKey:VALUE], \
                                                   editable, UIKeyboardTypeAlphabet, @"", identifier)];
                        value = @[@{TITLE: @"Envelope", TYPE: @(type), ROWS: rows }];
                        break;

                    case SPTypePickerList:
                    {
                        pickerDictionary = [NSDictionary dictionaryWithObjects:(NSArray *)value
                                                                       forKeys:[value valueForKey:VALUE]];
                        initialValue = pickerDictionary[valuesIn[rowDictionary[IDENTIFIER]]][NAME];
                        
                        // If we have a default value for the identifier we provide the envelope with 2 rows.
                        if (valuesDefault[rowDictionary[IDENTIFIER]]) {
                            
                            // We do have a default value; let's create two rows with the first row
                            // as the default value. We also remove the default value from the choices.

                            NSMutableArray *defaultOmitted = [value mutableCopy];
                            NSDictionary *defaultValue = pickerDictionary[valuesDefault[rowDictionary[IDENTIFIER]]];
                            [defaultOmitted removeObject:defaultValue];
                            
                            // If the initial value of the property is equal to the default value we'll choose
                            // the first choice as the initial value for the picker view.
                            if ([initialValue isEqualToString:defaultValue[NAME]] || !initialValue)
                                initialValue = [defaultOmitted firstObject][NAME];
                            pickerList = @[
                                           P_ROW(defaultValue[NAME], SPTypeChoice, \
                                                 defaultValue[VALUE], YES, UIKeyboardTypeDefault, @"ca", identifier),
                                           P_ROW(initialValue, SPTypePickerView, defaultOmitted, YES, 0, @"", identifier),
                                           ];
                        } else {
                            // We only have a single row as there is now default value.
                            pickerList = @[
                                           P_ROW(initialValue, SPTypePickerView, value, YES, 0, @"", identifier)
                                           ];
                        }
                        value = @[
                                  @{TITLE: @"", TYPE: @(SPTypeSimpleList), ROWS: pickerList, KEY: identifier}
                                  ];
                    }

                        break;
                    default:
                        break;
                }
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
                
                // Check if we have a non-empty property list. Proceed if so. Request one through the
                // delegate method otherwise. The test for class NSArray is a bit crappy. 
                
                settingsViewController = [[SettingsViewController alloc] init];
                [settingsViewController setDelegate:delegate];
                if ([NSStringFromClass([value class]) rangeOfString:@"NSArray"].location < 3) {
                    [settingsViewController setPropertyList:(NSArray *)value];
                    settingsViewController.valuesId = identifier;
                    [settingsViewController setValuesIn:self.valuesIn];
                    [settingsViewController setValuesDefault:self.valuesDefault];
                } else {
                    NSAssert([delegate respondsToSelector:@selector(willChangePropertiesForRow:)],
                             @"Must provide a propertiesForRow: delegate method for %@", rowDictionary[identifier]);
                    [settingsViewController setPropertiesForRow:rowDictionary];
                    settingsViewController.valuesId = identifier;
                    [settingsViewController setValuesIn:self.valuesIn];
                    [settingsViewController setValuesDefault:self.valuesDefault];
                }
                [settingsViewController setNestingLevel:nestingLevel + 1];
            }
            [settingsViewController setTitle:rowDictionary[NAME]];
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

#pragma mark
#pragma mark - SettingsViewCell implementation


@implementation SettingsViewCell

    static UIView *lastEditedField;


@synthesize textField, textView, webView, rowDictionary, viewController, button;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    // We define UITableViewCellStyleValue1 as the default style. It may be overwritten, though,
    // in the case of a custom settings cell.
    
    if (style == UITableViewCellStyleDefault)
        style = UITableViewCellStyleValue1;

    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialize cell
        if ([reuseIdentifier isEqualToString:cellIdentifierDefault]) {

            // Add a textField for the parameter display and editing.
            textField = [[UITextField alloc] initWithFrame:(CGRect){0.0f, 0.0f, 250.0f, 20.0f}];
            [textField setDelegate:self];
            [textField setBackgroundColor:[UIColor clearColor]];
            
            [textField setTextAlignment:NSTextAlignmentLeft];
            [textField setUserInteractionEnabled:YES];
            [textField setReturnKeyType:UIReturnKeyDone];

            [textField setKeyboardAppearance:UIKeyboardAppearanceLight];
            [textField setKeyboardType:UIKeyboardTypeAlphabet];
         
            // iOS 8 introduced a UIInputViewController which handles custom keyboard views.
            // For some reasons I use somewhere a setting that maked iOS believe I'm using a custom
            // keyboard. The property is read-only but it can be overwritten in the interface
            // definition to read-write. Settings the inputViewController property access to read-write
            // fixes the '-[InputViewController _keyboard]: unrecognized selector...' issue. Note that
            // it's not even necessary to overwrite the value with nil.
        }
    }

    textView = nil;
    
    return self;
}

- (void)layoutSubviews {
    
    // Let the labels size themselves to accommodate their text
    [super layoutSubviews];
    
    [self.textLabel sizeToFit];
    [self.detailTextLabel sizeToFit];
    CGRect textFrame, detailFrame = self.detailTextLabel.frame;
    CGFloat offset = -20.0f;
    
    NSString *htmlString;
    NSAttributedString *attributedString;
    NSData *data;
    NSError *error;
    
    UIColor *blackColor = [UIColor blackColor];
    UIColor *dimmedColor = [UIColor lightGrayColor];

    // We need to reset some cell type specific view in order to avoid confusion.
    [self.textField removeFromSuperview];
    [self.textView removeFromSuperview];
    
    // To align settings values nicely we use kind of tabs. A text label should start at
    // one of the tab stops.
    
    NSInteger tabs = 40, indent = (NSInteger) self.textLabel.frame.size.width;
    indent = tabs * (2 + indent / tabs);
    
    // Adjust textField for input.
    SettingsPropertyType type = (SettingsPropertyType)[rowDictionary[TYPE] integerValue];
    
    switch (type) {
        case SPTypeInteger32:
        case SPTypeDecimal:
        case SPTypeDate:
            [self.textField setTextAlignment:NSTextAlignmentRight];
            
        case SPTypeChoice:

            // We check here if the VALUE field in the row dictionary is empty. If so we'll assume
            // that this is a self-updating picker list in which we can write a new value on row 0.
            // In which case we'll treat row 0 like an editable text field.
            
            if ([[self.detailTextLabel text] length] == 0 && [rowDictionary[VALUE]  isEqual: @""]) {
                [self.detailTextLabel setText:@" "];
            }
            
        case SPTypeString:
            
            // String properties are left justified. We need to trick the tableView cell here as
            // the UITableViewCellStyleValue1 style has the detailTextLabel right justified but we
            // want it to be left justified.
            
            textFrame = (CGRect){indent, detailFrame.origin.y,
                self.contentView.frame.size.width - indent - 40.0f, detailFrame.size.height};
            [self.textField setText:self.detailTextLabel.text];
            [self.textField setFont:[UIFont systemFontOfSize:self.detailTextLabel.font.pointSize]];
            if ([rowDictionary[EDIT] boolValue])
                [self.textField setTextColor:blackColor];
            else
                [self.textField setTextColor:dimmedColor];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.textField setFrame:textFrame];
            [self.textField setTextAlignment:NSTextAlignmentRight];
            [self.contentView addSubview:textField];
            [self.textView removeFromSuperview];
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
            [self.textField removeFromSuperview];
            [self.textLabel setHidden:YES];
            [self.detailTextLabel setHidden:YES];
            if ([self.textView dataDetectorTypes] > 0) {
                [self.textView setSelectable:YES];
            } else
                [self.textView setSelectable:NO];
            
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
            [self.textField removeFromSuperview];
            [self.textLabel setHidden:YES];
            [self.detailTextLabel setHidden:YES];
            
            break;
            
        case SPTypeMultiValue:
            
            // Multi-value properties cannot be changed on this level and so the current value is
            // informative and displayed right justified.
            
            textFrame = (CGRect){detailFrame.origin.x + offset, detailFrame.origin.y,
                detailFrame.size.width -= offset, detailFrame.size.height};
            [self.textField setText:self.detailTextLabel.text];
            [self.textField setFont:[UIFont systemFontOfSize:self.detailTextLabel.font.pointSize]];
            [self.textField setTextColor:dimmedColor];
            [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
            [self.textField setFrame:textFrame];
            [self.textField setTextAlignment:NSTextAlignmentRight];
            [self.contentView addSubview:textField];
            [self.textView removeFromSuperview];
            [self.textLabel setHidden:NO];
            [self.detailTextLabel setHidden:YES];
            
            break;
            
        case SPTypeSimpleList:
            
            // Make sure that any remaining text from a previous cell is not displayed here.
            // We just want the accessory mark.

            [self.detailTextLabel setHidden:YES];
            break;
            
        case SPTypeCustom:

            // We don't perform anything in layoutSubviews for the custom cell. All the formatting
            // has to be done on the delegate protocol method for custom cells.
            
            break;
            
        case SPTypeAction:

            // We need to reset the button frame again - it may have been resized. Another iOS 8 feature...
            [self.button setFrame:self.contentView.frame];
            break;

        case SPTypePList:
        default:
            
            [self.detailTextLabel setHidden:NO];
            [self.detailTextLabel setTextColor:dimmedColor];
            [self.textLabel setHidden:NO];

            break;
    }
}

- (void)switchOnOff:(id)sender {
    
    // This method implements the Boolean property type. The callback triggered by the user touching the switch.
    // The status is read from the switch and both values dictionaries are updated.
    
    UISwitch *onOffSwitch = (UISwitch *)self.accessoryView;
    [viewController didChange:@(onOffSwitch.on) forRow:rowDictionary];
}

- (void)buttonSelected:(id)sender {
    
    // Method triggered by a selected button for an action type property. This method
    // invokes the user defined callback for the property.
    
    NSString *selector = rowDictionary[FLAGS];
    NSString *value = rowDictionary[IDENTIFIER];
    SEL action = NSSelectorFromString(selector);

    NSMethodSignature *signature = [(UIViewController *)viewController.delegate methodSignatureForSelector:action];

    // At this point we still may have a textField that is still firstResponder. This seems to be the
    // only way to force an end of the editing so that we actually get the correct value (for the user ID and
    // the password).
    
    [lastEditedField endEditing:YES];
    
    // Since we want the callback to return the UIControlState of the button we need to use NSInvocation
    // class to capture the return value.
    
    if (value) {
        
        UIControlState controlState;
        if ([viewController.delegate respondsToSelector:action]) {
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                        [[viewController.delegate class] instanceMethodSignatureForSelector:action]];
            [invocation setSelector:action];
            [invocation setTarget:viewController.delegate];
            [invocation setArgument:&sender atIndex:2];
            if ([signature numberOfArguments] > 3)
                [invocation setArgument:&rowDictionary atIndex:3];

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

- (void)textFieldDidBeginEditing:(UITextField *)aTextField {

    // Keep the last edited textField so we can end editing when the user jumps to an action button directly.
    lastEditedField = aTextField;
}

- (void)textFieldDidEndEditing:(UITextField *)aTextField {
    
    // Dismiss keyboard, give up first responder capability. Then read the string and update both values dictionaries.
    // Triggered when the user ends editing by jumping to the next property.
    
    NSObject *value;
    [aTextField endEditing:YES];

    // TODO: We have a problem here that we get the wrong rowDictionary when we skip fields during editing.
    // if (self.tag != viewController.selectedIndexPath.row) {
    //     NSDictionary *rd = [viewController rowDictionary:viewController.selectedIndexPath];
    //     NSLog(@"Cell(%li) label(%@) name(%@) sp(%@)", (long)self.tag, self.textLabel.text, rowDictionary[IDENTIFIER], rd[IDENTIFIER]);
    // }

    // Do some data type conversion here, specifically string to number
    // formats. e don't handle any validation errors and just use the simple
    // conversion method offered by the integerValue and floatValue methods.
    
    switch ((SettingsPropertyType)[rowDictionary[TYPE] integerValue]) {
        case SPTypeInteger32:
            value = @([[aTextField text] integerValue]);
            break;

        case SPTypeDecimal:
            value = @([[aTextField text] floatValue]);
            break;

        case SPTypeDate:
            // TODO: Add date conversion here.
            break;

        case SPTypeChoice:
            value = [aTextField text];
        {
            NSMutableDictionary *newRow = [rowDictionary mutableCopy];
            [newRow addEntriesFromDictionary:[NSDictionary dictionaryWithObject:value forKey:NAME]];
            rowDictionary = newRow;
        }
            break;
            
        default:
            value = [aTextField text];
            break;
    }
    [viewController didChange:value forRow:rowDictionary];
}

- (BOOL)textFieldShouldReturn:(UITextField *)aTextField {
    
    // Dismiss keyboard, give up first responder capability. Triggered when the user hits return on the keyboard.
    [aTextField endEditing:YES];
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
    
    // Keep the last edited textField so we can end editing when the user jumps to an action button directly.
    lastEditedField = aTextView;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView {
    
    // Dismiss keyboard, give up first responder capability. Triggered when the user hits return on the keyboard.
    [aTextView endEditing:YES];
    [viewController didChange:aTextView.text forRow:rowDictionary];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
    
    [aTextView endEditing:YES];
    [viewController didChange:aTextView.text forRow:rowDictionary];
}

- (void)textViewDidChange:(UITextView *)textView {
    
}

@end

@implementation SettingsPickerView

@synthesize parentCell = _parentCell;
@synthesize choices = _choices;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = (id<UIPickerViewDelegate>)self;
        self.dataSource = (id<UIPickerViewDataSource>)self;
        [self setUserInteractionEnabled:YES];
        
    }
    return self;
}

- (SettingsViewCell *)parentCell { return _parentCell; }
- (void)setParentCell:(SettingsViewCell *)parentCell { _parentCell = parentCell; }

- (NSArray *)choices { return _choices; }
- (void)setChoices:(NSArray *)choices { _choices = choices; }

#pragma mark -
#pragma mark SettingsPickerViewController DataSource and Delegate methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return [_choices count];
    
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    
    return [_choices objectAtIndex:row][NAME];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    
    SettingsViewController *viewController = (SettingsViewController *)[self.parentCell viewController];
    NSObject *value = [_choices objectAtIndex:row][VALUE];
    [[self.parentCell textLabel] setText:[_choices objectAtIndex:row][NAME]];

    // We also need to select the row of the parent cell. For some reasons we need to explicitly send
    // the willSelectRowAtIndexPath to the delegate.
    
    NSIndexPath *indexPath = [viewController.tableView indexPathForCell:self.parentCell];
    [viewController.tableView.delegate tableView:viewController.tableView willSelectRowAtIndexPath:indexPath];

    // Notify the delegate method of the change.
    [viewController didChange:value forRow:self.parentCell.rowDictionary];
}

@end


@implementation SettingsTextView

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    return NO;
}

@end
