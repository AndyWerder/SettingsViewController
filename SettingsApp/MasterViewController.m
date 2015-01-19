//
//  MasterViewController.m
//  SettingsApp
//
//  Created by Andreas Werder on 1/19/14.
//  Copyright (c) 2014, 2015 Andreas Werder. All rights reserved.
//
//  This App has no other functionality than to demonstrate some of
//  the features of the SettingsViewController class.
//

#import "MasterViewController.h"
#import "SettingsViewController.h"


@interface MasterViewController () {
  
    NSArray *_objects;
    NSString *cellIdentifier;
    
    SettingsViewController *settingsViewController;
    BOOL isFLipped;
}

@end


@implementation MasterViewController

- (id)initWithStyle:(UITableViewStyle)style {
    
    self = [super initWithStyle:style];
    return self;    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];

    cellIdentifier = @"MasterCell";
    [self.tableView registerClass:[MasterViewControllerCell class] forCellReuseIdentifier:cellIdentifier];
    [self.tableView setDataSource:(id)self];

    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(settings)];
    self.navigationItem.rightBarButtonItem = settingsButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    _objects = @[
                 P_MULTIVALUE(@"fullname",          @"Guest"),
                 P_MULTIVALUE(@"userId",            @"guest"),
                 P_MULTIVALUE(@"password",          @"anon"),
                 P_MULTIVALUE(@"emailAddress",      @"guest.name@gmail.com"),
                 P_MULTIVALUE(@"background",        @(BackgroundColorWhite)),
                 P_MULTIVALUE(@"iCloud",            @(YES)),
                 P_MULTIVALUE(@"option",            @(NO)),
                 P_MULTIVALUE(@"level",             @(1)),
                 P_MULTIVALUE(@"textView",          @"1\n2\n3\n4\n5"),
                 P_MULTIVALUE(@"integer",           @(31 * 59)),
                 P_MULTIVALUE(@"decimal",           @(99.9))
                 ];
    
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    
    settingsViewController = nil;
    _objects = nil;
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SettingsViewController configuration

- (void)settings {
    
    //  This launches the SettingsVewController. The property list array must be provided
    //  as an input parameter to the init method.
    //  The SettingsViewController can be invoked in two ways:
    //  1)  As a modal view of the MasterViewController; in this case it will have to be
    //      initialized as RootViewController under the MasterViewController's
    //      NavigationViewController. See example below.
    //  2)  As a TableViewController on the MasterViewConroller's viewcontroller stack.
    //      In this case it would have to be invoked using the NavigationViewController's
    //      pushViewController:animated method:
    //
    //      [self.navigationController pushViewController:settingsViewController animated:YES];
    //
    //      This second option is typically used when the MasterViewController is under a
    //      SplitViewController. Furthermore, the method for dismissing the SettingsViewController
    //      must be adopted so that control to the involing MasterViewController is returned
    //      through a popViewControllerAnimated: call.
    //
    //  as an input parameter to the init method. The view controller must be presented
    //  within a navigation controller.
    
    NSArray *keys = [self pListKeys];
    isFLipped = NO;
    
    settingsViewController = [[SettingsViewController alloc] initWithProperties:keys];
    [settingsViewController setDelegate:self];
    
    // Create a Navigation controller
    UINavigationController *mnc = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    [mnc setModalPresentationStyle:UIModalPresentationFormSheet];
    
    // show the view controller
    [self presentViewController:mnc animated:YES completion:^{
        NSLog(@"Presented settings view controller");
    }];
}

- (NSArray *)pListKeys {
    
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

    id null = [NSNull null];
    NSString *noFlags = @"";
    NSString *capitalized = @"c";
    NSString *secure = @"s";
    
    NSString *header = @"The SettingsViewController supports strings, numbers, boolean values and multi-value " \
                        "choices. Furthermore it allows to have nested property list. A row on level 1 can consist " \
                        "of a group (or section) of properties on level 2.";
    NSString *footer = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor" \
                        "incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud" \
                        "exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ";
    
    // Set up property sub-list for user account, login ID, email etc.
    NSArray *login = @[
                      P_ROW(@"Name", SPTypeString, null, YES, UIKeyboardTypeAlphabet, capitalized, @"fullname"),
                      P_ROW(@"User Id", SPTypeString, null, YES, UIKeyboardTypeAlphabet, noFlags, @"userId"),
                      P_ROW(@"Password", SPTypeString, null, YES, UIKeyboardTypeAlphabet, secure, @"password"),  //
                      P_ROW(@"Email Address", SPTypeString, null, YES, UIKeyboardTypeEmailAddress, noFlags, @"emailAddress")
                      ];
    
    NSArray *buttonStates = @[
                              P_MULTIVALUE(@"Flip", @(UIControlStateNormal)),
                              P_MULTIVALUE(@"Flop", @(UIControlStateSelected)),
                              ];
    
    NSArray *userType = @[
                          P_ROW(@"Type", SPTypeAction, buttonStates, YES, 0, NSStringFromSelector(@selector(flipFlop:)), @"subscriptionType")
                          ];
    
    NSArray *subPlist = @[
                          P_SECTION(@"User", @"user", null, login, @"To validate login, please use Log In button"),
                          P_SECTION(@"Subscription", @"subscription", null, userType, footer)
                          ];
    
    // Set up top-level (main) property list
    NSArray *user = @[
                              P_ROW(@"Name", SPTypeString, @(0), NO, UIKeyboardTypeAlphabet, capitalized, @"fullname"),
                              P_ROW(@"Log In", SPTypePList, subPlist, NO, UIKeyboardTypeDefault, noFlags, @"emailAddress")
                              ];
    
    // The General group shows an example of a multi-value list and boolean switches.
    NSArray *background = @[
                             P_MULTIVALUE(@"White", @(BackgroundColorWhite)),
                             P_MULTIVALUE(@"Yellow", @(BackgroundColorYellow)),
                             P_MULTIVALUE(@"Green", @(BackgroundColorGreeen)),
                             P_MULTIVALUE(@"Blue", @(BackgroundColorBlue))
                             ];
    NSArray *general = @[
                         P_ROW(@"Background", SPTypeMultiValue, background, YES, UIKeyboardTypeDefault, noFlags, @"background"),
                         P_ROW(@"Use iCloud (non-editable)", SPTypeBoolean, @(1), NO, UIKeyboardTypeDefault, noFlags, @"iCloud"),
                         P_ROW(@"Switch", SPTypeBoolean, @(1), YES, UIKeyboardTypeDefault, noFlags, @"option")
                         ];

    // The Level group is a simple list and provides the choice between BEGINNER and EXPERT level.
    // Note that a simple list should only have one row per section; other rows will be ignored.
    NSArray *levels = @[
                        P_MULTIVALUE(@"Beginner", @(1)),
                        P_MULTIVALUE(@"Expert", @(2)),
                        ];
    NSArray *level = @[
                       P_ROW(@"Level", SPTypeSimpleList, levels, YES, 0, noFlags, @"level"),
                       ];

    // Example of a multi-line text view.
    NSArray *response = @[
                          P_MULTIVALUE(@"Reply", @(1)),
                          P_MULTIVALUE(@"Reply to All", @(2)),
                          P_MULTIVALUE(@"Forward", @(3)),
                          ];
    
    NSArray *message = @[
                         P_ROW(@"Message Response", SPTypeMultiValue, response, YES, UIKeyboardTypeDefault, noFlags, @"response"),
                         P_ROW(@"Instructions", SPTypeMultilineText, @"This is a text view", YES, UIKeyboardTypeAlphabet, @"a", @"textView")
                         ];

    NSArray *baseList = @[
                          P_ROW(@"Integer Field", SPTypeInteger32, null, YES, UIKeyboardTypeDecimalPad, noFlags, @"integer"),
                          P_ROW(@"Decimal Field", SPTypeDecimal, null, YES, UIKeyboardTypeDecimalPad, @"", @"decimal"),
                          ];
    
    NSArray *baseTypes = @[
                           P_ROW(@"Edit Base Types", SPTypePList, @[
                                                                    P_SECTION(@"Base Types", @"baseTypes", null, baseList, null)
                                                                    ] , NO, UIKeyboardTypeDefault, noFlags, @"decimal")
                           ];

    // Define groups on top level
    NSArray *plist = @[
                       P_SECTION(@"User", @"user", null, user, null),
                       P_SECTION(@"General", @"general", header, general, null),
                       P_SECTION(@"Message", @"message", null, message, null),
                       P_SECTION(@"Level", @"level", null, level, @"A footer text"),
                       P_SECTION(@"Base Types", @"basic", null, baseTypes, @"A footer text"),
                       ];
    
    return plist;
}

- (NSArray *)settingsOutput:(NSDictionary *)dictionary {
    
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:5];
    NSArray *keys = [dictionary allKeys];
    
    for (NSString *key in keys)
        [objects addObject:[NSDictionary dictionaryWithObjects:@[key, [dictionary valueForKey:key]]
                                                       forKeys:@[@"name", @"value"]]];
    return objects;
}

- (UIControlState)flipFlop:(id)sender {

    // Method that shows the use of a two-state action button. The methid must return
    // the target control state when the action has completed.
    
    UIButton *button = (UIButton *)sender;
    [button setHighlighted:NO];
    UIControlState targetState = UIControlStateNormal;
    
    if (isFLipped)
        targetState = UIControlStateNormal;
    else
        targetState = UIControlStateSelected;

    isFLipped = !isFLipped;
    return targetState;
}

#pragma mark - SettingsViewController Delegate Methods

- (NSDictionary *)settingsInput:(id)sender {
    
    // This method is called once when the SettingsViewController is launched. The result
    // provided in the method is the initial set of named values that will be used to fill in
    // the property list.
    
    NSDictionary *values = [NSDictionary dictionaryWithObjects:[_objects valueForKey:@"value"]
                                                       forKeys:[_objects valueForKey:@"name"]];
    return values;
}

- (void)settingsDidChange:(id)value forRow:(NSDictionary *)row {

    //  SettingsViewController Delegate method that is triggered every time the user ends
    //  editing a property. The callback can be used to update configurations or settings
    //  based on that property.
    //  Note that SettingsViewController only supports a <Done>. A <Cancel> is not supported.
    //  All changes to property values are posted immediately when the text field for the property
    //  has resigned as first responder. Changes cannot be un-done by the app (but the use can
    //  undo them at any time, of course).
    
    NSString *name = row[@"identifier"];
    NSLog(@"%@ value(%@) name(%@)", NSStringFromSelector(_cmd), value, name);
    
    if ([name isEqualToString:@"background"]) {

        BackgroundColor colorValue = (BackgroundColor)[value integerValue];
        UIColor *background;
        
        switch (colorValue) {
            case BackgroundColorWhite:
                background = [UIColor whiteColor];
                break;
            case BackgroundColorYellow:
                background = [UIColor yellowColor];
                break;
            case BackgroundColorGreeen:
                background = [UIColor greenColor];
                break;
            case BackgroundColorBlue:
                background = [UIColor colorWithRed:0.6 green:0.6 blue:1.0 alpha:1.0];
                break;
            default:
                break;
        }
        [self.view setBackgroundColor:background];
    }
}

- (void)didDismissModalView:(id)sender {
    
    //  SettingsViewController Delegate method called when the user ends the SettingsApp by pressing
    //  the <Done> button. One of the methods to dismiss a modal view controller must be invoked so
    //  that the view controller is released properly and no storage is leaked. It provides also
    //  an exit point where the consolidated result of the SettingsApp can be captured before the
    //  SettingsViewController is dismissed.
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        NSDictionary *valuesOut = [settingsViewController valuesOut];
        __block NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:[_objects count]];
        [_objects enumerateObjectsUsingBlock:^(NSDictionary *object, NSUInteger idx, BOOL *stop){
            if (valuesOut[object[@"name"]])
                [objects addObject:[NSDictionary dictionaryWithObjects:@[valuesOut[object[@"name"]], object[@"name"]] forKeys:@[@"value", @"name"]]];
            else
                [objects addObject:[_objects objectAtIndex:idx]];
        }];
        _objects = objects;
        [self.tableView reloadData];
    }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    NSDictionary *object = _objects[indexPath.row];
    cell.textLabel.text = [object valueForKey:@"name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [object valueForKey:@"value"]];
    
    return cell;
}

@end

@implementation MasterViewControllerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

@end
