//
//  CoreEditingDetailView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/16/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "CoreEditingDetailView.h"


@implementation CoreEditingDetailView

@synthesize cancelButton;
@synthesize sortDescriptors;
@synthesize managedObject;
@synthesize managedObjectContext;

@synthesize detailDelegate;
@synthesize appDelegate;
@synthesize entityName;
@synthesize canEdit;

@synthesize fetchedResultsController, fetchPredicate;


- (void) viewDidLoad {
	
	//	self.managedObjectContext = appDelegate.rootViewController.managedObjectContext;
	
	self.appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];

	// NSLog(@"Predicate=%@", self.fetchPredicate);
	
	NSFetchedResultsController * frc = self.fetchedResultsController;
	
	[frc.fetchRequest setPredicate:self.fetchPredicate];
	
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		[appDelegate processError:error];
		return;
	} else {
		NSInteger count = [fetchedResultsController.fetchedObjects count];
		if (count) {
			self.managedObject = [fetchedResultsController.fetchedObjects objectAtIndex:0];
		}
	}

	[self loadDataFromManagedObject];
	
	if (self.canEdit) {
		[self.navigationItem setRightBarButtonItem:self.editButtonItem animated:YES];
		[self enableEdits:NO];
		self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
	}
	
}

- (void)viewDidUnload {
	
	//	self.managedObject = nil;
	
	self.entityName = nil;
	self.cancelButton = nil;
	self.fetchPredicate = nil;
	self.fetchedResultsController = nil;
	self.sortDescriptors = nil;

    [super viewDidUnload];
}

- (void)dealloc {

	//	[managedObject release];

	[cancelButton release];
	[fetchedResultsController release];
	[fetchPredicate release];
	[entityName release];
	[sortDescriptors release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) loadDataFromManagedObject {
}

- (void) copyDataToManagedObject {
}

- (void) enableEdits:(BOOL) enable {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	//	if (textField == nameTextField) {
	[textField resignFirstResponder];
	[self save];
	//}
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    
	[self enableEdits:editing];
	
	[self.navigationItem setHidesBackButton:editing animated:YES];
	
	/*
	 If editing is finished, save the managed object context.
	 */
	if(!editing) {

		if(self.navigationItem.leftBarButtonItem == cancelButton) {
			[self save];
		}

	} else {
		[self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];

	}

}

- (BOOL)save {
    [self copyDataToManagedObject];
	
	NSError *error = nil;
	if ([self.managedObjectContext save:&error]) {
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
		[self.detailDelegate saved];
		return YES;
	} else if (error != nil) {
		
		[self processError:error];

		[self setEditing:YES animated:YES];
		
		
	}
	return NO;
    
}

- (void)cancel {
	
    [self loadDataFromManagedObject];
	[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	[self setEditing:NO animated:YES];
	
}

- (void)done {
}

 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	 return YES;
 }

-(void) processError:(NSError *) error {
	[self.appDelegate processError:error];
}

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
	NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:appDelegate.managedObjectContext];
	[fetchRequest setEntity:entity];
	[fetchRequest setSortDescriptors:self.sortDescriptors];
	
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:appDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;
	
	[aFetchedResultsController release];
	[fetchRequest release];
	
	return fetchedResultsController;
}    


#pragma mark -
#pragma mark NSFetchedResultsController Delegate Methods

/*
 - (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
 // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
 //NSLog(@"controllerWillChangeContent");
 //[self.tableView beginUpdates];
 }
 */
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// this gets called if the song got updated elsewhere...so update the UI with the new data, too.
	[self performSelectorOnMainThread:@selector(loadDataFromManagedObject) withObject:nil waitUntilDone:NO];
}
/*
 - (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
 //UITableView *tableView = self.tableView;
 
 switch(type) {
 case NSFetchedResultsChangeDelete:
 //NSLog(@"NSFetchedResultsChangeDelete");
 break;
 case NSFetchedResultsChangeUpdate:
 //NSLog(@"NSFetchedResultsChangeUpdate");
 break;
 }
 }
 */

@end
