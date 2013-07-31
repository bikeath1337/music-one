//
//  MissedViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/18/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "MissedViewController.h"
#import "PlayerEventNotifications.h"

@implementation MissedViewController
- (void) viewDidLoad {

	self.viewTitle = NSLocalizedStringFromTable(@"Missed", @"Tables", nil);
	self.entityName = @"Song";
	self.timeStampKey = @"missedDate";

	self.songNameColor = [UIColor redColor];

	// sort descriptor
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"missedDate" ascending:NO];
	self.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
	
	NSString * predString = [NSString stringWithFormat:@"missed == 1"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	self.queryPredicate = predicate;
	
	[super viewDidLoad];

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];
	
	return [self formatCell:tableView managedObject:managedObject forSong:managedObject];
}


@end

