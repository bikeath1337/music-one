// 
//  Station.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/14/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "Station.h"

#import "Song.h"
#import "StreamOption.h"

@implementation Station 

@dynamic stationName;
@dynamic stationDescription;
@dynamic webSiteUrl;
@dynamic stationEmailAddress;
@dynamic timeZoneID;

@dynamic songs;
@dynamic streamOptions;

- (void)encodeWithCoder:(NSCoder *)encoder {
		
	if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:self.stationDescription forKey:@"stationDescription"];
        [encoder encodeObject:self.stationName forKey:@"stationName"];
        [encoder encodeObject:self.stationEmailAddress forKey:@"stationEmailAddress"];
        [encoder encodeObject:self.webSiteUrl forKey:@"webSiteUrl"];
    }
    else {
        // Must decode keys in same order as encodeWithCoder:
        [encoder encodeObject:self.stationDescription];
        [encoder encodeObject:self.stationName];
        [encoder encodeObject:self.stationEmailAddress];
        [encoder encodeObject:self.webSiteUrl];
    }
	
}
- (id)initWithCoder:(NSCoder *)decoder {
	
    if ([decoder allowsKeyedCoding]) {
        self.stationDescription = [decoder decodeObjectForKey:@"stationDescription"];
        self.stationName = [decoder decodeObjectForKey:@"stationName"];
        self.stationEmailAddress = [decoder decodeObjectForKey:@"stationEmailAddress"];
        self.webSiteUrl = [decoder decodeObjectForKey:@"websiteUrl"];
    }
    else {
        // Must decode keys in same order as encodeWithCoder:
        self.stationDescription = [decoder decodeObject];
        self.stationName = [decoder decodeObject];
        self.stationEmailAddress = [decoder decodeObject];
        self.webSiteUrl = [decoder decodeObject];
    }
    return self;
	
}


@end
