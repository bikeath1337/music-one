// 
//  Song.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/14/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "Song.h"
#import "RecentlyPlayed.h"
#import "Station.h"

@implementation Song 

@dynamic mix;
@dynamic composer;
@dynamic artist;
@dynamic songID;
@dynamic name;
@dynamic fullSongName;
@dynamic year;
@dynamic dj;
@dynamic recentlyPlayed;
@dynamic favorite;
@dynamic rating;
@dynamic ratingSent;
@dynamic lastRefresh;
@dynamic topSong;
@dynamic station;
@dynamic addedOnTimestamp;
@dynamic exclusive;
@dynamic missed;
@dynamic missedDate;
@dynamic topSongSequence;

+ (NSString *) getArtistMix:(NSManagedObject *)song {
	NSString * artistMix = [song valueForKey:@"artist"];
	if([[song valueForKey:@"mix"] length]) {
		if ([artistMix length]) {
			artistMix = [artistMix stringByAppendingString:@" - "];
		}
		artistMix = [artistMix stringByAppendingString:[song valueForKey:@"mix"]];
	}
	return artistMix;
}

- (void) saveFavorite: (NSNumber *) fave {
		
		[self setValue:fave forKey:@"favorite"];
		
		NSError *error = nil;
		if (![self.managedObjectContext save:&error]) {
			if(error != nil) { 
				NSLog(@"Error saving favorite");
			} 
		}
}	

- (void) saveRating: (NSNumber *) newRating {
	
	[self setValue:newRating forKey:@"rating"];
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"ratingSent"];
	[self setValue:[NSNumber numberWithBool:([newRating intValue] > 0) ? YES: NO] forKey:@"favorite"];	
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		if(error != nil) { 
			NSLog(@"Error saving rating");
		} 
	}
}	

- (CGFloat) getLabelWidth:(UILabel *) label songColumn:(NSString *) columnName margin:(CGFloat) margin {
	NSString * text = [self valueForKey:columnName];
	if(![text length]) {
		return 0; // margin;
	}
	return [text sizeWithFont:label.font].width + margin;
}

- (void) setLabelText:(UILabel *) label songColumn:(NSString *) columnName margin:(CGFloat) margin{
	CGRect labelrect = label.frame;
	labelrect.size.width = [self getLabelWidth:label songColumn:columnName margin:margin];
	label.frame = labelrect;
	label.text = [self valueForKey:columnName];
	NSLog(@"text=%@", label.text);
}

@end
