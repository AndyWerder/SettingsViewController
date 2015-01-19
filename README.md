SettingsViewController
======================

Self-contained class to provide an iPad Settings app-like user interface for managing application specific settings. SettingsViewController is a subclass of UITableView and uses the grouped style. It supports multiple nesting levels. The settings are managed by a property list kept in an NSDictionary as properties. The property list is built outside of the class. The SettingsViewController.h file provides macros for facilitating the building the property list.

SettingsViewController supports several types of settings:

Single level types
------------------
- **String:** Single line strings can be used for names, credentials (including passwords). A number of settings parameters support keyboard type, auto-correction and capitalization plus password obfuscation.
- **Integer32:** A simple short or long integer for presentation and editing.
- **Decimal:** A number for presentation and editing.
- **Boolean:** The user interface for Boolean settings is based on the switch (UISwitch) control.
- **Date:** A full date/time stamp, presentation only (editing not supported).
- **Multi-line text:** Provides a textView that spans across the entire cell for free text entry and editing.
- **HTML:** Provides a Web view that spans across the entire cell for presenting HTML content.
- **Simple list:** A list of mutually exclusive choices. The value of the selected row becomes the result. The simple list is similar to the multi-value list except that it presents all choices on the current level. Note that a simple list must be the only property in the respective section and cannot be combined with other fields in its section.

Multi-level types  
-----------------
Multi-level types invoke the SettingsViewController recursively for as many levels as required.

- **Multi-value:** Provides a drop-down list like interface using a second level of the SettingsViewController. The multi-value type is based on a title-value tuple per choice. The controller displays the title but the result returned is given by the corresponding value for the title.
- **Picker List:** Similar to the multi-value option, a Picker List allows the selection of a specific value from a list but through the Picker metaphor. Providing a default value will result in a simple list for which the user can select either the default or the picker value. 
- **Property list:** The property list is again a dictionary with the same structure as the top level property list. Any level of recursive nesting is supported.
- **Action:** The action type is implemented with a custom style UIButton. The button title can be configured for several UIControlState values thus permitting On/Off kind or even multi-state buttons. A button can trigger one selector which must be implemented by the SettingViewController Delegate (but which is not part of the Delegate protocol).
- **Custom:** The custom type is used to provide a specific format for a (read-only) property. Formatting must be done in delegate protocol methods for the SettingsViewCell. For instance, it can be used to display a thumbnail next to a sub-title. The style of the cell can be configured and the callbacks available are used to specify height and cell context for presenting the property.

Input Values
------------
The initial settings to be used in the property list must be provided in a (flat) NSDictionary structure of name/value tuples. Additionally, default values can be provided that are used in the Picker List type.

Output Values
-------------
Changed values are provided in a NSMutableDictionary with the same structure as the input values, i.e. name/value tuples. Only changed values are returned in the output values dictionary. If no changes have been made, the resulting dictionary will be empty.

Interface
---------

`- (id)initWithProperties:(NSArray *)properties:`
Constructor for SettingsViewController which takes a dictionary of settings parameters (see above) as only input argument. 

`- (void)didChange:(id)value forKey:(NSString *)name:`
Interface method that can be used to pass a settings value back to the SettingsViewController. This is usually required when a callback is used in conjunction with a setting (e.g. a login validation method and the validated login parameters must be included in the settings). 

`- (void)dismissViewController:`
Interface method that can be used to dismiss the SettingsViewController programmatically from the outside without the need to press the Done button.

Delegate Protocol
-----------------
The SettingsViewController uses provides protocol for mandatory and optional methods to be implemented by the calling class.

`-settingsInput:sender:`
Required callback used to provide a dictionary of name/value tuples to be used as initial values in the propery lists. The names of the values presented must match the identifier provided for the particular property.

`-propertiesForRow:rowDictionary:`
Optional callback that implements the dynamic composition of recursive Property lists. The method is called every time a property list is being built dynamically. To take correct action the rowDictionary parameter must be checked for instance for the IDENTIFIER.

`-settingsDefault:sender:`
Optional callback similar to the settingsInput method which is used to provide default values for properties. The method must return a dictionary of default name/value pairs.  

`-settingsDidChange:forKey:`
Callback that is invoked in the protocol delegate whenever a value from the property list has been changed by the user.

`-willDismissModalView:sender:`
Callback invoked BEFORE the didDismissModalView:sender: method is invoked. The callback can be used to determine if the SettingsViewControlller has to be dismissed for instance when changes to the properties must be committed.

`-didDismissModalView:`
Callback that must implement one of the dismissController methods used by the UIViewController class to release a controller.

Delegate Protocol for Custom type properties
--------------------------------------------


`-customSetting:heightForRowAtIndexPath:`
Optional callback that can be used to specifiy the height of a Custom cell. The indexPath parameter must be used to distinguish between custom cells if multiple properties are formatted with custom cells.

`-customSetting:cellForRowAtIndexPath:`
Optional callback for format a SettingsViewCell. Again, the indexPath parameter must be used to distinguish between different custom cells if multiple properties are formatted with custom cells. The method is similar to the tableView:cellForRowAtIndexPath: method and it must return a correctly built SettimngsViewCell object. The style of the cell must be specified by the VALUE parameter of the row dictionary.

Extension for Class SettingsViewCell 
------------------------------------
The SettingsViewCell class can be extended in the parent view controller to add standard functionality for editing properties. To edit multi-line or HTML text fields, a UITextView field is used which implements the canPerformAction:withSender: callback to support a context menu. The extension can be used to overwrite the default behavior.
