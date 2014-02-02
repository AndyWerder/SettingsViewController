		//
//  LookupViewController.m
//  ChefsHand
//
//  Created by Andreas Werder on 1/17/11.
//  Copyright 2011 Material Apps. All rights reserved.
//
//  Changes history:
//  2011-01-17  First version
//  2011-03-02  Turned the lookup controller into a tableview controller 
//  2011-03-04  Beautified the tableview and the cells  
//  2011-03-07  Adjusted controller to new navigation framework
//  2011-03-11  Added activity indicator, synch is now performed in the background
//  2011-03-25  Moved splitView controller delegate to synopsis view controller
//  2012-03-06  Replaced the footerView by a toolbar using the refresh system button item
//  2012-03-06  The toolbar is now attached to the navigation controller and does not scroll
//  2013-07-28  Completed new Apple compliant design of SplitViewController
//  2013-09-07  Replaced SynopsisController by InputDetailViewController as detail view controller
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "ChefsHandAppDelegate.h"
#import "RootViewController.h"
#import "RootMenuController.h"
#import "LookupViewController.h"
#import "InputDetailViewController.h"
#import "HomeTableView.h"
#import "ChefsHandDataHandler.h"
#import "ChefsHandEntity.h"
#import "Recipe+Extensions.h"
#import "LocalDictionary+Extensions.h"
#import "UINavigationController+Extensions.h"
#import "SettingsViewController.h"
#import "Constants.h"
#import "BackgroundTheme.h"

@interface LookupViewController () {
    
    ChefsHandAppDelegate *delegate;
    NSDictionary *sectionDictionary;
    UIToolbar *toolbar;
	UILabel *footerLabel;
	UILabel *footerAILabel;
    UIBarButtonItem *synchButtonItem;
    UIBarButtonItem *settingsButtonItem;
    UIBarButtonItem *spaceButtonItem;
    BackgroundTheme *theme;

    SettingsViewController *settingsViewController;
    UIPopoverController *popoverController;
}

- (void)synchRecipes;
- (void)synchCompleted:(NSNotification *)notification;
- (void)settings;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)edit;
- (NSArray *)pListKeys;


@end


@implementation LookupViewController

@synthesize fetchedRecipesController;
@synthesize progressView, isHidden;
@synthesize detailL1client;

- (void)edit {
    
}

- (id)init {
    
    self = [super init];
    if (self) {
        [self setTitle:@"My Recipes"];
        isHidden = YES;

        // Establish addressability of application delegate and ManagedObjectsContext
        delegate = [[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void) loadView {
    
	[super loadView];
    
    // Establish addressability of application delegate and ManagedObjectsContext
    detailL1client = delegate.inputDetailViewController;

    // Define the background view based on the preferences
    theme = [[BackgroundTheme alloc] initWithStyle:backdropViewStyleCountertop type:backdropViewTypeTable];
    [self.tableView setBackgroundView:theme];
	
    [self.tableView setDelegate:self];
	[self.tableView setSeparatorColor:[UIColor whiteColor]]; 
	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine]; 
	[self setClearsSelectionOnViewWillAppear:NO];
    [self.tableView setRowHeight:LookupTableViewRowHeight];
    [self.tableView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 44.0f, 0.0f)];    // Bottom inset same as height of toolbar

	// We need a text label for the synch message plus a separate label for the activity indicator.
	footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0f, 14.0f, 200.0f, 17.0f)];
    [footerLabel setBackgroundColor:[UIColor clearColor]];
	[footerLabel setFont:[UIFont systemFontOfSize:14.0f]];
	[footerLabel setTextColor:[UIColor darkGrayColor]];
	[footerLabel setTextAlignment:NSTextAlignmentLeft];

	footerAILabel = [[UILabel alloc] initWithFrame:CGRectMake(280.0f, 14.0f, 20.0f, 20.0f)];
	[footerAILabel setBackgroundColor:[UIColor clearColor]];

	// Initialize the section title dictionary; this allows to look up the section name for the section value.
    LocalDictionary *class = [delegate dictionaryLookup:@[@"class"]];
    NSArray *allClasses = [[class hasLocalDictionary] allObjects];
    sectionDictionary = [NSDictionary dictionaryWithObjects:[allClasses valueForKey:@"noun"]
                                                    forKeys:[allClasses valueForKey:@"value"]];

    // Set up navigation bar and toolbar attached to it on the (left) split tableview side.
    // We used to have this part in -viewWillAppear: callback (and the symmetric removeFromSuperView calls
    // in -viewWillDisappear:) but it is safe enough to do this just once.
    
    CGRect nbFrame = [self.navigationController.toolbar frame];
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, nbFrame.origin.y - 44.0f, 320.0f, 44.0f)];
    toolbar.barStyle = UIBarStyleDefault;
    
	// We use the refresh system item for the synch button, just like in the Apple Mail app. The synch button is
    // the only button item on the footer view which is actually a toolbar.

    synchButtonItem = SYSBARBUTTON(UIBarButtonSystemItemRefresh, @selector(synchRecipes));
    settingsButtonItem = IMGBARBUTTON([UIImage imageNamed:@"ButtonSettings.png"], @selector(settings));
    spaceButtonItem = SYSBARBUTTON(UIBarButtonSystemItemFlexibleSpace, nil);

	[toolbar addSubview:footerLabel];
	[toolbar addSubview:footerAILabel];
    [toolbar setItems:@[synchButtonItem, spaceButtonItem, settingsButtonItem] animated:NO];
    [self.navigationController.view addSubview:toolbar];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear: animated];
    
    [delegate.rootSplitViewController setDelegate:self];
    [self.navigationItem setHidesBackButton:NO];
    // editButton = [self editButtonItem];
    // [self.navigationItem setRightBarButtonItem:editButton];
    
    // This section is critical for the control of the splitviews; it re-establishes a proper master/detail
    // splitView with Lookup/Synopsis controllers and replaces the full screen detail view that is presented
    // initially and which just shows the favorites. With this change the delegate is changed from the
    // MasterViewController (initial detail view) to the LookupViewController.

    /*
    UINavigationController *dnc = [self.splitViewController.viewControllers lastObject];
    [self.splitViewController setDelegate:nil];
    [self.splitViewController setDelegate:self];
    [self.splitViewController willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation
                                                      duration:0];
    [dnc pushViewController:synopsisController animated:YES];
     */

    [toolbar setHidden:NO];
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    
	// Display details of the first recipe at indexpath row 0. Becuase of the timing
    // we need to do this in the viewDidAppear method instead of the viewWillAppear. 
    [super viewDidAppear:animated];
    
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	Recipe *recipe = (Recipe *)[fetchedRecipesController objectAtIndexPath:indexPath];
    [self showRecipe:recipe];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    /*
    [self.splitViewController setDelegate:nil];
    [self.splitViewController setDelegate:delegate.rootMenuController];
    [self.splitViewController.view setNeedsDisplay];

    UINavigationController *dnc = [self.splitViewController.viewControllers lastObject];
    [dnc popViewControllerAnimated:YES];
    NSLog(@"viewWillDisappear mainViewController(%p) %p", delegate.rootMenuController, self.splitViewController.delegate);
    [self.splitViewController willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation
                                                      duration:0];
     
     */

    // We'll keep the footer views but get rid of the toolbar - otherwise it'll stick to the navigation
    // controller view. Also, we check if this master viewcontroller was removed from the viewcontroller stck.
    // If so, this is an indication that the user selected the Home backbutton and we also pop the
    // detail viewcontroller.
    
    UINavigationController *nc = self.navigationController;
    if ([nc didPopController:self]) {
        UINavigationController *dnc = [self.splitViewController.viewControllers lastObject];
        [dnc popViewControllerAnimated:YES];
    }
    
    [progressView removeFromSuperview];
    [toolbar setHidden:YES];
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    
    // Save changed if required; use the rootMenu viewcontroller's update flag to check.
    if ([delegate.rootMenuController updateRootMenu]) {
        NSError *error = nil;
        [delegate.managedObjectContext save:&error];
        if (error)
            NSLog(@"Error: %@", [error localizedDescription]);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
    return YES;
}

- (void)reloadData {
    
    // Refresh the data in the fetched results controller for the recipe list.
    NSError *error = nil;
    self.fetchedRecipesController = nil;
    
	if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"LookupViewController: Error %@, %@", error, [error userInfo]);
	} else
        NSLog(@"LookupViewController: Fetched %i entries", [[fetchedRecipesController fetchedObjects] count]);

    [self.tableView reloadData];
}

- (void)synchRecipes {

	// Synch the database with the web based database; synchronization is done in 
	// the ChefsHand application delegate. Since we show the activity indicator 
    // we must perform the synchDatabase asynchronously but in the main thread. 
    // Synchronization with the result of the update is done through a callback
    // fired by the didSave notification for the managedObject context. 

    NSLog(@"Synching database");
    
    // Before we do anything else we need to nil the action to avoid calling synchRecipes
    // a second time. Also, we need to disable the Home segment in order to avoid an error
    // when merging the two managed contexts.
    
    [synchButtonItem setAction:nil];

    footerLabel.text = @"";
    progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [progressView setFrame:CGRectMake(footerLabel.frame.origin.x, 15.0f, 180.0f, 10.0f)];
    [progressView setProgressTintColor:[UIColor darkGrayColor]];
    [progressView setTrackTintColor:[UIColor whiteColor]];
    
    [toolbar addSubview:progressView];
    [progressView setProgress:0.0f animated:YES];
    NSLog(@"ProgressView(%p)", progressView);

    // Since the SSL connection for the download of the data from the Chefshand site is
    // asynchronous we need to run the whole update process in a background thread.
    // This is turn means that we need to set up the background thread's own MO context and
    // persistent store-coordinator. We start this up by spawning the resynchDatabase from
    // the main thread. Until the update in the background thread is complete, the purpose of
    // the main thread is only to update the progress view.
    
    [delegate performSelectorInBackground:@selector(resynchDatabase:) withObject:self];
}

- (void)synchCompleted:(NSNotification *)notification {
        
	// Complete the synching; this method is called asynchronously and triggered by the didSave
    // notification issued by synchDatabase in the ChefsHand appdelegate. It's main purpose is to
    // merge the changes made to the managed object contect in the background thread with the context
    // of the main thread. This always has to be done in the main thread so the method is recursive.
    
    if (![NSThread isMainThread]) {
        NSLog(@"Re-launching the background MOC merge in the main thread");
        [self performSelectorOnMainThread:@selector(synchCompleted:) withObject:notification waitUntilDone:YES];
        return;
    } else {

        // This block always runs in the main thread. Firsth thing to do is merging the MO contexts.

        UIAlertView *alertView;
        [delegate.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        
        // Now remove the progress view and display an updated message in the footer view. If the synching
        // was not successful because the Internet was not able we'll also through a

        NSString *message;
        NSDate *synchDate = [delegate lastSynched];

        if (synchDate) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"M/dd/YY h:mm a"];
            message = [NSString stringWithFormat:@"Updated %@", [dateFormatter stringFromDate:synchDate]];
            NSLog(@"Re-synching of database complete %@", [dateFormatter stringFromDate:synchDate]);
        } else {
            message = @"Failed to update";
            [self.progressView setProgress:1.0f];
            alertView = [[UIAlertView alloc] initWithTitle:@"Synch Recipes" message:[delegate synchError]
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
            [alertView show];
            NSLog(@"Re-synch failed with error: %@", [delegate synchError]);
        }
        
        [progressView removeFromSuperview];
        footerLabel.text = message;
        [delegate setSynchError:@""];
        
        // Restore the action when pressing the re-synch button and enable the Home sgement again.
        [synchButtonItem setAction:@selector(synchRecipes)];
        [delegate.rootMenuController setUpdateRootMenu:YES];
        
        // Re-initialize fetchedResultsController and reload tableview data
        [self reloadData];
    }
}

- (void)settings {
    
    NSArray *keys = [self pListKeys];
    
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
    
    // Create the property list arrays and dictionaries

    id null = [NSNull null];
    NSString *noFlags = @"";
    NSString *capitalized = @"c";
    NSString *secure = @"s";
 
    // Set up property sub-list for user account, login ID, email etc.
    NSArray *user = @[
                      P_ROW(@"Name", SPTypeString, null, YES, UIKeyboardTypeAlphabet, capitalized, @"fullname"),
                      P_ROW(@"User Id", SPTypeString, null, YES, UIKeyboardTypeAlphabet, noFlags, @"userId"),
                      P_ROW(@"Password", SPTypeString, null, YES, UIKeyboardTypeAlphabet, secure, @"password"),  //
                      P_ROW(@"Email Address", SPTypeString, null, YES, UIKeyboardTypeEmailAddress, noFlags, @"emailAddress")
                      ];
    NSArray *subscriptionType = @[
                                  P_ROW(@"Type", SPTypeString, null, YES, UIKeyboardTypeAlphabet, noFlags, @"subscriptionType")
                                  ];
    
    NSArray *subPlist = @[
                          P_SECTION(@"User", null, user, null),
                          P_SECTION(@"Subscription", null, subscriptionType, null)
                          ];
    
    // Set up top-level (main) property list
    NSArray *subscription = @[
                      P_ROW(@"Name", SPTypeString, @(0), NO, UIKeyboardTypeAlphabet, capitalized, @"fullname"),
                      P_ROW(@"Log In", SPTypePList, subPlist, NO, UIKeyboardTypeDefault, noFlags, @"emailAddress")
                      ];
    
    NSArray *countertops = @[
                             P_MULTIVALUE(@"Plain", @(backdropViewStylePlain)),
                             P_MULTIVALUE(@"Sandstone, grey", @(backdropViewStyleSandstone)),
                             P_MULTIVALUE(@"Nanocort, titanium", @(backdropViewStyleNancortTitanium)),
                             P_MULTIVALUE(@"Nanocort, copper", @(backdropViewStyleNancortCopper))
                             ];
    NSArray *general = @[
                            P_ROW(@"Countertop", SPTypeMultiValue, countertops, YES, UIKeyboardTypeDefault, noFlags, @"countertop"),
                            P_ROW(@"Use iCloud", SPTypeBoolean, @(1), NO, UIKeyboardTypeDefault, noFlags, @"iCloud")
                            ];
    
    NSArray *scheduler = @[
                               P_ROW(@"Late Scheduling", SPTypeBoolean, @(0), YES, UIKeyboardTypeDefault, noFlags, @"lateScheduling"),
                               P_ROW(@"Auto Confirm Ingredients", SPTypeBoolean, @(0), YES, UIKeyboardTypeDefault, noFlags, @"autoConfirm")
                               ];
    
    NSArray *plist = @[
                       P_SECTION(@"Subscription", null, subscription, null),
                       P_SECTION(@"General", null, general, null),
                       P_SECTION(@"Scheduler", null, scheduler, null)
                       ];
    
    return plist;
}

- (NSDictionary *)settingsInput:(id)sender {
    
    NSDictionary *values = @{
                             @"fullname":       @"Andreas Werder",
                             @"userId":         @"andreas",
                             @"password":       @"changeit",
                             @"emailAddress":   @"andreas.werder@yahoo.com",
                             @"loginVerified":  @(NO),
                             @"countertop":     @([BackgroundTheme currentTheme]),
                             @"iCloud":         @(YES),
                             @"lateScheduling": @(NO),
                             @"autoConfirm":    @(YES)
                             };
    return values;
}

- (void)settingsDidChange:(id)value forKey:(NSString *)name {
    
    NSLog(@"LookupViewController changed value(%@) for property(%@)", value, name);
    
}

- (void)didDismissModalView:(id)sender {
    
    // Dismiss the modal view controller
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        NSDictionary *valuesOut = [settingsViewController valuesOut];
        NSLog(@"View controller dismissed; changed keys=%@", [valuesOut allKeys]);
    }];
}

#pragma mark -
#pragma mark TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	// Number of rows in use.
	NSInteger count = [[fetchedRecipesController sections] count];
    return (count == 0) ? 1 : count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	// Number of rows currently in this table 
    NSInteger numberOfRows = 0;
	
    if ([[fetchedRecipesController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedRecipesController sections] objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // Dequeue or if necessary create a RecipeTableViewCell, then set its recipe to the recipe for the current row.
	// For some reason the image doesn't load when subclassing the UITableViewCell for the lookup cell, so
	// we use the plain UITableViewCell class. 
	
	UITableViewCellStyle style =  UITableViewCellStyleSubtitle;
	UITableViewCell *cell = [tView dequeueReusableCellWithIdentifier:@"BaseCell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:@"BaseCell"];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	// User has selected a recipe line; show him the details.
	Recipe *recipe = (Recipe *)[fetchedRecipesController objectAtIndexPath:indexPath];
    [self showRecipe:recipe];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	
	// Set the image and the text label for the lookup cells. We use the opportunity here to check if
    // the recipe has an image; if not we overwrite it with the default and make sure the change is
    // saved to the database at the end.

	Recipe *recipe = (Recipe *)[fetchedRecipesController objectAtIndexPath:indexPath];
	UIImage *image = [delegate tryReadingImage:[recipe image]];
    if (!image) {
        image = [UIImage imageNamed:@"Recipe"];
        [recipe setImage:@"Recipe"];
        [delegate.rootMenuController setUpdateRootMenu:@"YES"];
    }
	cell.imageView.image = image; 
	cell.textLabel.text = [recipe shortTitle];
    cell.detailTextLabel.text = [recipe titleCaption];
}

- (void)showRecipe:(Recipe *)aRecipe {
    
	// Synch the detailview in the InputDetailViewController
	[detailL1client performSelector:@selector(propagateSelectedRecipe:) withObject:aRecipe];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // We use Remove (Favorite) rather than Delete for the delete button.
    return @"Remove";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Return YES if you want the specified item to be editable. 
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // To remove a recipe entry from the list of recipes we just set the delete flag to YES.
        // Everything else will be taken care of by the UITableView delegate methods.
        
        Recipe *recipe = [fetchedRecipesController objectAtIndexPath:indexPath];
        [recipe setDelete:@(YES)];
        [delegate saveContext];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    // Return the title for a specific section
	NSArray *titles = [fetchedRecipesController sectionIndexTitles];
    if (section < [titles count])
        return [titles objectAtIndex:section];
    else
        return @"Error";
}

#pragma mark -
#pragma mark Fetched results controller

//
//  FetchedResultsController for Lookup View
//  ChefsHand
//
//  Changes history:
//  2011-03-02  Added the fetchedResultsController and the delegate methods
//  2011-03-11  Improved reliability during synching by adding Jeff LaMarche's code
//


- (NSFetchedResultsController *)fetchedResultsController {
	
    // Set up the fetched results controller if needed.
	
    if (fetchedRecipesController == nil) {
        
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:
                                    @"section > 0 && delete == NO && isProject == NO"]];
                                    // @"(dictionary.name == 'entree' || dictionary.name == 'dessert' || dictionary.name == 'appetizer' || dictionary.name = 'salad') "
        NSEntityDescription *entity = [NSEntityDescription entityForName:EntityRecipe inManagedObjectContext:delegate.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
        NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        [fetchRequest setSortDescriptors:@[sortDescriptor1, sortDescriptor2]];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																									managedObjectContext:delegate.managedObjectContext
																									  sectionNameKeyPath:@"section" 
																											   cacheName:nil];
        aFetchedResultsController.delegate = self;
        self.fetchedRecipesController = aFetchedResultsController;
    }
	
	return fetchedRecipesController;
}    

#pragma mark -
#pragma mark Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {

	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	[self.tableView beginUpdates];

}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject 
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type 
      newIndexPath:(NSIndexPath *)newIndexPath {
	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller 
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
           atIndex:(NSUInteger)sectionIndex 
     forChangeType:(NSFetchedResultsChangeType)type {
    
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName {
    
	NSString *title;
    
    // Look up the class value in the dictionary and return the associated noun.
    NSString *noun = [sectionDictionary objectForKey:@([sectionName integerValue])];
    if (noun)
        title = [NSString stringWithFormat:@"%@s", noun];
    else
        title = [NSString stringWithFormat:@"Other %i", [sectionName integerValue]];
    
    return title;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    
	[self.tableView endUpdates];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark UISplitViewController delegate methods

- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem*)barButtonItem
       forPopoverController:(UIPopoverController*)pc {
    
    [barButtonItem setTitle:self.title];
    UINavigationController *nc = svc.viewControllers[1];
    [nc.topViewController.navigationItem setLeftBarButtonItem:barButtonItem];
    popoverController = pc;
}

- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    
    UINavigationController *nc = svc.viewControllers[1];
    [nc.topViewController.navigationItem setLeftBarButtonItem:nil];
    svc.navigationController.navigationBar.hidden = YES;
    popoverController = nil;
}

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation {
    
    return UIInterfaceOrientationIsPortrait(orientation);
}

/*
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    
    NSLog(@"LookupViewController: popoverControllerShouldDismissPopover");
    return NO;
}
 */

@end
