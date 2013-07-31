//
//  FavoritesViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/16/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "SongTableViewController.h"
#import "FavoritesViewController.h"
#import "Song.h"
#import "SongDetailView.h"
#import "MusicPlayerController.h"


@implementation FavoritesViewController

- (void) viewDidLoad {

	self.viewTitle = NSLocalizedStringFromTable(@"Favorites", @"Tables", nil);
	self.entityName = @"Song";
	self.canDelete = YES;
	
	self.coreEditingDelegate = self;
	self.canClearAll = YES;
	
	// sort descriptor
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	self.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
	
	NSString * predString = [NSString stringWithFormat:@"favorite == 1"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	self.queryPredicate = predicate;
	
	[super viewDidLoad];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {

		NSManagedObject * songToUpdateFavorite = [fetchedResultsController objectAtIndexPath:indexPath];

		// favorites aren't deleted, they are just updated to reflect a new attribute
		[self doDelete:songToUpdateFavorite];

		// Save the context.
		NSError *error;
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		if (![context save:&error]) {
			[self processError:error];
		}
    }   
}

- (void) doDelete: (NSManagedObject *) managedObject {
	[managedObject setValue:[NSNumber numberWithBool:NO] forKey:@"favorite"];
}


@end