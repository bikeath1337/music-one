//
//  RootViewController.m
//  LocationsX
//
//  Created by Bobby Wallace on 01/11/2010.
//  Copyright Total Managed Fitness 2010. All rights reserved.
//

#import "CoreDataEditingTableViewController.h"
#import "RecentlyPlayed.h"
#import "CoreDataBase.h"
#import "Song.h"


@implementation CoreDataEditingTableViewController

@synthesize canChange, canInsert, canDelete, canClearAll;
@synthesize viewTitle;
@synthesize entityName;
@synthesize tblCacheName;
@synthesize sortDescriptors;
@synthesize queryPredicate;

@synthesize coreEditingDelegate;
@synthesize cancelButton, addButton, clearAllButton, skipPopulate;

@synthesize fetchedResultsController, managedObjectContext, appDelegate;

- (void)viewDidLoad {
    [super viewDidLoad];

	self.appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
	
	// Set up the edit and add buttons.
	self.title = self.viewTitle;
	
	if(self.canChange || self.canInsert || self.canDelete) {
		
		[self.navigationItem setRightBarButtonItem:self.editButtonItem animated:YES];

	}
    
	if(self.canInsert) {
		self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
		//self.navigationItem.leftBarButtonItem = addButton;
		addButton.enabled = NO;
	}
	
	if(self.canClearAll) {
		self.clearAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Clear", @"Buttons", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(clearAll)];
	}

	if (skipPopulate) {

	} else {
		NSError *error = nil;
		if (![self.fetchedResultsController performFetch:&error]) {
			[self processError:error];
		}
	}

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release anything that can be recreated in viewDidLoad or on demand.
    self.addButton = nil;
	self.viewTitle = nil;
	self.entityName = nil;
	self.tblCacheName = nil;
	self.sortDescriptors = nil;
	self.coreEditingDelegate = nil;
	
	self.queryPredicate = nil;
	
	self.fetchedResultsController = nil;

}

- (void)dealloc {
	[viewTitle release];
	[entityName release];
	[tblCacheName release];
	[sortDescriptors release];
	[fetchedResultsController release];
    [addButton release];
	[queryPredicate release];
    [super dealloc];
}

#pragma mark Table view methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {

    [super setEditing:editing animated:animated];

    if (self.navigationController == nil) {
		// table controller is nested and doesn't control the navigation controller
		return;
	}
	[self.navigationItem setHidesBackButton:editing animated:YES];
	
	if(!editing) {
		
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
		
	} else {
		if(self.canClearAll){
			[self.navigationItem setLeftBarButtonItem:clearAllButton animated:YES];
		}
		
	}
	
}

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	//NSLog(@"%d", [[fetchedResultsController sections] count]);
    return [[fetchedResultsController sections] count];
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray * sections = [fetchedResultsController sections];
	if (sections && [sections count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
		//NSLog(@"%@ %d, %d", self.tblCacheName, [sectionInfo numberOfObjects], section);
		return [sectionInfo numberOfObjects];
	} else {
		return 0;
	}

}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.viewTitle;
}
*/
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.

	if (self.canChange) {
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	}
	NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];
	
	[self.coreEditingDelegate configureTableCell:cell managedObject:managedObject];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSManagedObject *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	[self.coreEditingDelegate showDetail:selectedObject forRow:indexPath];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.canChange || self.canDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		[context deleteObject:[fetchedResultsController objectAtIndexPath:indexPath]];
		
		// Save the context.
		NSError *error = nil;
		if (![context save:&error]) {
			[self processError:error];
		}
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The table view should not be re-orderable.
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    NSIndexPath *target = proposedDestinationIndexPath;
    
    /*
     make sure that it's not the Add object row -- if it is, retarget for the penultimate row.
     */
	//NSUInteger proposedSection = proposedDestinationIndexPath.section;
	
	NSUInteger rows_1 = [[fetchedResultsController sections] count] - 1;
	
	if (proposedDestinationIndexPath.row > rows_1) {
		target = [NSIndexPath indexPathForRow:rows_1 inSection:0];
	}
	return target;
}
	

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
	/*
	 Update the ingredients array in response to the move.
	 Update the display order indexes within the range of the move.
	 */
    //Ingredient *ingredient = [ingredients objectAtIndex:fromIndexPath.row];
	//NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
/*
	[[self fetchedResultsController] 
    [ingredients removeObjectAtIndex:fromIndexPath.row];
    [ingredients insertObject:ingredient atIndex:toIndexPath.row];
	
	NSInteger start = fromIndexPath.row;
	if (toIndexPath.row < start) {
		start = toIndexPath.row;
	}
	NSInteger end = toIndexPath.row;
	if (fromIndexPath.row > end) {
		end = fromIndexPath.row;
	}
	for (NSInteger i = start; i <= end; i++) {
		ingredient = [ingredients objectAtIndex:i];
		ingredient.displayOrder = [NSNumber numberWithInteger:i];
	}
 */
}
/*
- (void)setNilValueForKey:(NSString *)theKey
{
    if ([theKey isEqualToString:@"fetchedResultsController"]) {
        [self setValue:[NSNumber numberWithBool:YES] forKey:@"hidden"];
    } else
        [super setNilValueForKey:theKey];
}
*/

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    /*
	 Set up the fetched results controller.
	*/
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	
	if([self.sortDescriptors count]) {
		[fetchRequest setSortDescriptors:self.sortDescriptors];
	}
	
	if(self.queryPredicate != nil) {
		[fetchRequest setPredicate:self.queryPredicate];
	}
	
	// Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
									managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:self.tblCacheName];
    aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;
	
	[aFetchedResultsController release];
	[fetchRequest release];

	return fetchedResultsController;
}    

/**
 Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	[self.tableView beginUpdates];
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	[self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	UITableView *tableView = self.tableView;
	
	// This is the workaround.
	// only call this section if the managed object used here is actually one that has been extended to deal with the "bug"
	//NSLog(@"%d",  [[anObject class] instancesRespondToSelector:@selector(changedSection)]);
	//NSLog(@"%@", [anObject class]);
	if( (NSFetchedResultsChangeUpdate == type) && [[anObject class] instancesRespondToSelector:@selector(changedSection)] ) { 
		CoreDataBase *changedInstance = (CoreDataBase *)anObject;
		if ( [changedInstance changedSection] ) {
			[changedInstance  setChangedSection:NO];
			type = NSFetchedResultsChangeMove;
			newIndexPath = indexPath;
		}
	};

	switch(type) {
		case NSFetchedResultsChangeInsert:
			if(newIndexPath)
				[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			if(indexPath)
				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			if(indexPath)
				[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeMove:
			if(indexPath) {
				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
				//[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
				// Reloading the section inserts a new row and ensures that titles are updated appropriately.
				[tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

-(void) processError:(NSError *) error {
	[self.appDelegate processError:error];
}

- (void)saved:(NSManagedObject *)managedObject {
	[self.tableView reloadData];
}

- (void)done:(NSManagedObject *)managedObject {
}
- (void)cancel:(NSManagedObject *)managedObject {
}
- (void)saved {
	[self.tableView reloadData];
}

- (void)done {
}
- (void)cancel {
}
- (void)clearAll {
}

@end

