//
//  RecentsTableViewController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/20/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomerSongPickerView.h";


@interface RecentsTableViewController : CustomerSongPickerView {
	UIColor *songNameColor;
	NSString *timeStampKey;
}

@property (nonatomic, retain) UIColor *songNameColor;
@property (nonatomic, retain) NSString *timeStampKey;

- (NSString *) getRelativeTimeString:(NSDate *) date;
- (UITableViewCell *) formatCell:(UITableView *)tableView managedObject:(NSManagedObject *) managedObject forSong:song;
@end
