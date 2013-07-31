//
//  StreamOption.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/14/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CoreDataBase.h"
#import "IniPreferences.h"

typedef enum
	{
		SS_TYPE_SHOUTCAST = 0,
		SS_TYPE_ICY
	} StreamingStationServerType;

@class Station;

@interface StreamOption :  CoreDataBase  
{
}

@property (nonatomic, retain) NSNumber * priority;
@property (nonatomic, retain) NSString * playlistUrl;
@property (nonatomic, retain) NSString * urlString;
@property (nonatomic, retain) NSNumber * icyMetaTitleCompliant;
@property (nonatomic, retain) NSNumber * streamType;
@property (nonatomic, retain) NSNumber * serverType;
@property (nonatomic, retain) NSString * contentType;
@property (nonatomic, retain) NSString * serverTimeZone;
@property (nonatomic, retain) NSString * streamDescription;
@property (nonatomic, retain) NSString * bpsDescription;
@property (nonatomic, retain) Station * station;

@end



