//
//  RootViewController.h
//  LocationsX
//
//  Created by Bobby Wallace on 01/11/2010.
//  Copyright Total Managed Fitness 2010. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MusicPlayerAppDelegate.h"

@protocol CoreDataEditingTableViewDelegate;

@interface CoreDataEditingTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate> {
	NSString * viewTitle;
	NSString * entityName;
	NSString * tblCacheName;
	
	NSArray * sortDescriptors;
	NSPredicate * queryPredicate;
	
	NSFetchedResultsController *fetchedResultsController;
	NSManagedObjectContext *managedObjectContext;
	MusicPlayerAppDelegate * appDelegate;

	UIBarButtonItem *addButton, *cancelButton, *clearAllButton;
	
	id <CoreDataEditingTableViewDelegate> coreEditingDelegate;
	
	BOOL canInsert;
	BOOL canChange;
	BOOL canDelete;
	BOOL canClearAll;
	
	BOOL skipPopulate;

}

@property (nonatomic, retain) UIBarButtonItem *  cancelButton, *addButton, *clearAllButton;

@property (nonatomic, assign) BOOL canInsert, canChange, canDelete, canClearAll, skipPopulate;

@property (nonatomic, retain) NSString * viewTitle;
@property (nonatomic, retain) NSString * tblCacheName;
@property (nonatomic, retain) NSString * entityName;
@property (nonatomic, retain) NSArray * sortDescriptors;
@property (nonatomic, retain) NSPredicate * queryPredicate;



@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, assign) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) MusicPlayerAppDelegate *appDelegate;
@property (nonatomic, assign) id <CoreDataEditingTableViewDelegate> coreEditingDelegate;

- (void) processError:(NSError *) error;

@end

@protocol CoreDataEditingTableViewDelegate
- (void)configureTableCell:(UITableViewCell *)cell managedObject: (NSManagedObject *)managedObject;
- (void)showDetail: (NSManagedObject *)managedObject forRow: (NSIndexPath *) indexPath;
- (void)insertNewObject;
@end
