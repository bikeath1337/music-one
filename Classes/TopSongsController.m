//
//  TopSongsController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/19/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "TopSongsController.h"
#import "SongTableViewController.h"
#import "Song.h"
#import "MusicPlayerController.h"

@implementation TopSongsController

@synthesize rankButtonTemplate;

- (void) viewDidLoad {
	
	self.viewTitle = NSLocalizedStringFromTable(@"TopRated", @"Tables", nil);
	self.tableType = Top;
	self.tblCacheName = @"TopSongs";

	self.canDelete = NO;
	
	// sort descriptor
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"topSongSequence" ascending:YES];
	self.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
	
	NSString * predString = [NSString stringWithFormat:@"topSong == 1"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	self.queryPredicate = predicate;
	
	//skipPopulate = YES;

	[super viewDidLoad];
	
}

- (void) viewDidUnload {
	[super viewDidUnload];
	self.rankButtonTemplate = nil;
}
- (void) dealloc {
	[super dealloc];
	[rankButtonTemplate release];
}

- (void) doClearAll {
	[super doClearAll];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsAreFresh]];
}

- (void) doDelete: (NSManagedObject *) managedObject {
	[managedObject setValue:[NSNumber numberWithBool:NO] forKey:@"topSong"];
}

- (NSString *) tableHeader:(NSInteger) section {
	
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	}
	
	NSDate * lastTopSongsStationTimestamp = [[NSUserDefaults standardUserDefaults] objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsStationTimestamp]];
	if (lastTopSongsStationTimestamp == nil) {
		lastTopSongsStationTimestamp = [appDelegate.rootViewController topSongsDate];
	}
	
	NSString * dateValue;
	dateValue = [dateFormatter stringFromDate:lastTopSongsStationTimestamp]	;

	return [NSString stringWithFormat:NSLocalizedStringFromTable(@"WeekOfFormat", @"Tables", nil), dateValue];
}


@end
