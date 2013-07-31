//
//  RecentlyPlayed.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/14/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CoreDataBase.h"

@class Song;

@interface RecentlyPlayed :  CoreDataBase  
{
}

@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, assign) BOOL missed;
@property (nonatomic, retain) Song * song;

@end



