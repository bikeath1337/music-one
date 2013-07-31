//
//  CoreDataBase.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/31/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CoreDataBase : NSManagedObject {
    BOOL _changedSection;
	id _theSectionKey;

}

// The modeled property that determines the object's section.
@property (nonatomic, retain) NSString *theSectionKey;

// The unmodeled property that tracks if a section was recently changed.
@property BOOL changedSection;

@end
