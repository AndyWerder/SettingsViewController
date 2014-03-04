SettingsViewController
======================

Self-contained class to provide an iPad Settings app-like user interface for managing application specific settings. SettingsViewController is a subclass of UITableView and uses the grouped style. It supports multiple nesting levels. The settings are managed by a property list kept in an NSDictionary as properties. The property list is built outside of the class. The SettingsViewController.h file provides macros for facilitating the building the property list.

SettingsViewController supports several types of settings:

Single level types
------------------
- **String:** Single line strings can be used for names, credentials (including passwords). A number of settings parameters support keyboard type, auto-correction and capitalization plus password obfuscation.
- **Integer32:** Yet to be implemented
- **Float:** Same as above
- **Boolean**: The user interface for Boolean settings is based on the switch (UISwitch) control.
- **Simple list:** A list of mutually exclusive choices. The value of the selected row becomes the result. The simple list is similar to the multi-value list except that it presents all choices on the current level.

Multi-level types  
-----------------
Multi-level types invoke the SettingsViewController recursively for as many levels as required.

- **Multi-value:** Provides a drop-down list like interface using a second level of the SettingsViewController. The multi-value type is based on a title-value tuple per choice. The controller displays the title but the result returned is given by the corresponding value for the title.
- **Property list:** The property list is again a dictionary with the same structure as the top level property list. Any level of recursive nesting is supported.
- **Action:** The action type is implemented with a custom style UIButton. The button title can be configured for several UIControlState values thus permitting On/Off kind or even multi-state buttons. A button can trigger one selector which must be implemented by the SettingViewController Delegate (but which is not part of the Delegate protocol).

Input Values
------------
The initial settings to be used in the property list must be provided in a (flat) NSDictionary structure of name/value tuples. 

Output Values
-------------
Changed values are provided in a NSMutableDictionary with the same structure as the input values, i.e. name/value tuples. Only changed values are returned in the output values dictionary. If no changes have been made, the resulting dictionary will be empty.

Delegate Protocol
-----------------
The SettingsViewController uses provides protocol for mandatory and optional methods to be implemented by the calling class.

`-settingsInput:sender`:
Callback used to provide a dictionary of name/value tuples to be used as initial values in the propery lists. The names of the values presented must match the identifier provided for the particular property.

`-settingsDidChange:forKey`:
Callback that is invoked in the protocol delegate whenever a value from the property list has been changed by the user.

`-didDismissModalView`:
Callback that must implement one of the dismissController methods used by the UIViewController class to release a controller.
