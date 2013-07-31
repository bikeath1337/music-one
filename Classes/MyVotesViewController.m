//
//  MyVotesViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/03/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "MyVotesViewController.h"
#import "MusicPlayerController.h"

@implementation MyVotesViewController

- (void) viewDidLoad {
	self.tableType = Favorite;

	self.viewTitle = NSLocalizedStringFromTable(@"Favorites", @"Tables", nil);
	self.entityName = @"Song";
	self.tblCacheName = @"Favorites";
	self.canDelete = YES;
	
	self.coreEditingDelegate = self;
	self.canClearAll = YES;
	
	// sort descriptor
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"rating" ascending:NO];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	self.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	
	NSString * predString = [NSString stringWithFormat:@"favorite == 1"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	self.queryPredicate = predicate;
	
	[super viewDidLoad];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Change for row at: %@", indexPath);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		NSManagedObject * songToUpdate = [fetchedResultsController objectAtIndexPath:indexPath];
		
		// My Votes aren't deleted, they are just updated to reflect a new attribute
		[self doDelete:songToUpdate];
		// Save the context.
		NSError *error = nil;
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		if (![context save:&error]) {
			[self processError:error];
		}
    }   
}

- (void) doDelete: (NSManagedObject *) managedObject {
    NSLog(@"deleting song");
	[managedObject setValue:[NSNumber numberWithInt:0] forKey:@"rating"];
	[managedObject setValue:[NSNumber numberWithBool:NO] forKey:@"favorite"];
}

- (UITableViewCell *) formatCell:(UITableView *)tableView managedObject:(NSManagedObject *) managedObject forSong:song {
	return nil;
}

- (NSString *) tableHeader:(NSInteger) section {
	
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}

	NSDate * lastVoteCleanupDate = [appDelegate.rootViewController.playerDelegate voteClearDate];
	NSDate * nextVotingStart =  [lastVoteCleanupDate dateByAddingTimeInterval:WEEK_IN_SECONDS]; // 1 week after the last voting 
	
	NSString * dateValue;
	dateValue = [dateFormatter stringFromDate:nextVotingStart];
	
	return [NSString stringWithFormat:NSLocalizedStringFromTable(@"VotesClearedOn", @"Tables", nil), dateValue];
}


@end