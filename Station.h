//
//  Station.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/14/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CoreDataBase.h"

@class Song;
@class StreamOption;

@interface Station :  CoreDataBase  <NSCoding>
{
}

@property (nonatomic, retain) NSString * stationName;
@property (nonatomic, retain) NSString * stationDescription;
@property (nonatomic, retain) NSString * webSiteUrl;
@property (nonatomic, retain) NSString * stationEmailAddress;
@property (nonatomic, retain) NSString * timeZoneID;

@property (nonatomic, retain) NSSet* songs;
@property (nonatomic, retain) NSSet* streamOptions;

@end

@interface Station (CoreDataGeneratedAccessors)
- (void)addSongsObject:(Song *)value;
- (void)removeSongsObject:(Song *)value;
- (void)addSongs:(NSSet *)value;
- (void)removeSongs:(NSSet *)value;

- (void)addStreamOptionsObject:(StreamOption *)value;
- (void)removeStreamOptionsObject:(StreamOption *)value;
- (void)addStreamOptions:(NSSet *)value;
- (void)removeStreamOptions:(NSSet *)value;

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

@end

