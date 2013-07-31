//
//  RecentsTableViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/20/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "RecentsTableViewController.h"
#import "SongPickerView.h"
#import "Song.h"
#import "PlayerEventNotifications.h"

@implementation RecentsTableViewController

@synthesize songNameColor;
@synthesize timeStampKey;

- (void) viewDidLoad {
	
	self.coreEditingDelegate = self;
	self.tableType = Recent;
	
	self.viewTitle = NSLocalizedStringFromTable(@"Recents", @"Tables", nil);
	self.entityName = @"RecentlyPlayed";
	self.tblCacheName = @"Recents";
	
	self.timeStampKey = @"timeStamp";
	// sort descriptor
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
	self.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
	
	//skipPopulate = YES;

	[super viewDidLoad];
}

- (void) viewDidUnload {
	[super viewDidUnload];
	self.songNameColor = nil;
}

- (void) dealloc {
	[songNameColor release];
	[super dealloc];
}
- (NSString *) getRelativeTimeString:(NSDate *) date {
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	//	static NSCalendar *gregorian = nil;
	if (gregorian == nil) {
		gregorian = [NSCalendar currentCalendar];
		//		gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	}
	static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
    }
	static NSDateFormatter *dayFormatter = nil;
    if (dayFormatter == nil) {
        dayFormatter = [[NSDateFormatter alloc] init];
		[dayFormatter setDateFormat:@"EEEE"];
    }
	static NSDateFormatter *timeFormatter = nil;
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
		[timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
	
	NSDate *now = [NSDate date];
	NSDateComponents *nowComponents =[gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:now];
	NSDateComponents *dateComponents =[gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
	
	if([nowComponents isEqual:dateComponents]) {
		// format date only for time for today
		return [[timeFormatter stringFromDate:date] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	
	NSDate *startOfNow = [gregorian dateFromComponents:nowComponents];
	NSDate *startOfDate = [gregorian dateFromComponents:dateComponents];
	
	NSTimeInterval seconds = [startOfNow timeIntervalSinceDate:startOfDate];
	// 86,400 = 1 day, 518,400 = 6 days
	NSTimeInterval days_6 = 6 * DAY_IN_SECONDS;
	if(seconds > DAY_IN_SECONDS && seconds < days_6){
		// format date only for dates before yesterday
		return [dayFormatter stringFromDate:date];
	}
	
	if(seconds >= days_6){ // just print date
		// format date only for dates before yesterday
		return [dateFormatter stringFromDate:date];
	}
	
	return NSLocalizedStringFromTable(@"Yesterday", @"Tables", nil);
	
}

- (UITableViewCell *) formatCell:(UITableView *)tableView managedObject:(NSManagedObject *) managedObject forSong:song {
	return nil;
}



@end

