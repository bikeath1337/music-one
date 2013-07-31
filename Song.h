//
//  Song.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/14/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CoreDataBase.h"

@class RecentlyPlayed;
@class Station;
@class Missed;

@interface Song :  CoreDataBase  
{
}

@property (nonatomic, retain) NSString * mix;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * composer;
@property (nonatomic, retain) NSNumber * songID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * fullSongName;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSString * dj;
@property (nonatomic, assign) BOOL * favorite;
@property (nonatomic, retain) NSDate * lastRefresh;
@property (nonatomic, assign) BOOL * topSong;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, assign) NSNumber * ratingSent;
@property (nonatomic, retain) Station * station;
@property (nonatomic, assign) BOOL missed;
@property (nonatomic, retain) NSDate * missedDate;
@property (nonatomic, retain) NSSet* recentlyPlayed;
@property (nonatomic, assign) BOOL * exclusive;
@property (nonatomic, retain) NSDate * addedOnTimestamp;
@property (nonatomic, retain) NSNumber * topSongSequence;

@end


@interface Song (CoreDataGeneratedAccessors)
- (void)addRecentlyPlayedObject:(RecentlyPlayed *)value;
- (void)removeRecentlyPlayedObject:(RecentlyPlayed *)value;
- (void)addRecentlyPlayed:(NSSet *)value;
- (void)removeRecentlyPlayed:(NSSet *)value;

+ (NSString *) getArtistMix:(NSManagedObject *)song;
- (void) saveRating: (NSNumber *) newRating;
- (void) saveFavorite: (NSNumber *) fave;
- (void) setLabelText:(UILabel *) label songColumn:(NSString *) columnName margin:(CGFloat) margin;
- (CGFloat) getLabelWidth:(UILabel *) label songColumn:(NSString *) columnName margin:(CGFloat) margin;
@end

