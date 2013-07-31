//
//  CoreDataBase.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/31/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

// NSFetchedResultsController: Moved Objects Sometimes Reported as Updated
// In some situations, an instance of NSFetchedResultsController may report moved objects using a NSFetchedResultsChangeUpdate 
// change notification instead of NSFetchedResultsChangeMove.

// A fetched results controller only sends object change notifications tagged as NSFetchedResultsChangeMove when the 
// original index path is different from the new index path. It's possible that a series of object changes can result 
// in an object being moved (such as moving to a new section), yet its relative index path remain the same (if other 
// object changes happened in objects that appear before the moved object). This scenario will result in a 
// NSFetchedResultsChangeUpdate notification being sent to the delegate.

// This class implements the workaround that apple suggested. See also the core table controller class "CoreEditingTableViewController"
// This property is used to determine if a change flagged as NSFetchedResultsChangeUpdate should actually be treated as a 
// NSFetchedResultsChangeMove by implementing controller:didChangeObject:atIndexPath:forChangeType:newIndexPath: 
// as adapted from their example:

#import "CoreDataBase.h"

@implementation CoreDataBase

@synthesize changedSection=_changedSection;
@synthesize theSectionKey=_theSectionKey;

- (void)setTheSectionKey:(id)value
{
    if (value != self.theSectionKey) {
        self.changedSection = YES;
    }
	
    [self willChangeValueForKey:@"theSectionKey"];
    [self setPrimitiveValue:value forKey:@"theSectionKey"];
    [self didChangeValueForKey:@"theSectionKey"];
}

@end
