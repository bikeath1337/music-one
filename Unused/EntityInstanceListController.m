//
//  EntityInstanceListController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/15/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "EntityInstanceListController.h"


@implementation EntityInstanceListController 

@synthesize titleAttribute, subTitleAttribute;

- (void) viewDidLoad {
	self.coreEditingDelegate = self;
	
	[super viewDidLoad];
}

- (void) viewDidUnload {
	self.titleAttribute = nil;
	self.subTitleAttribute = nil;
	[super viewDidUnload];
}

- (void) dealloc {
	[titleAttribute release];
	[subTitleAttribute release];
	[super dealloc];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void) configureTableCell: (UITableViewCell *) cell managedObject: (NSManagedObject *) managedObject {

	//	NSLog(@"%@", [managedObject valueForKey:self.titleAttribute]);
	cell.textLabel.text = [[managedObject valueForKey:self.titleAttribute] description];
	if( !([[managedObject valueForKey:self.titleAttribute] isEqual:[managedObject valueForKey:self.subTitleAttribute]])){
		cell.detailTextLabel.text = [[managedObject valueForKey:self.subTitleAttribute] description]; 
	}
}

- (void) insertNewObject {
}

- (void) showDetail: (NSManagedObject *) managedObject forRow:(NSIndexPath *) indexPath {
	NSString * detailClassName = [self.entityName stringByAppendingString:@"DetailView"];
	Class detailClass = (NSClassFromString(detailClassName));

	if(detailClass != nil) {
		NSObject * detailViewController = [[detailClass alloc] init];
		//detailViewController.navigationController.navigationBarHidden = NO;
		
		[detailViewController performSelector:@selector(setManagedObject:) withObject:managedObject ];
		[detailViewController performSelector:@selector(setManagedObjectContext:) withObject:self.managedObjectContext];
		[self.navigationController pushViewController:(UIViewController *) detailViewController animated:YES];
		
		[detailViewController release];
	}
}

@end

