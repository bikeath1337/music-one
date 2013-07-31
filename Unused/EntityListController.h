//
//  EntityListController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/15/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EntityListController : UITableViewController <UITableViewDataSource>{
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
	NSArray *entities;

}

@property (nonatomic, assign) NSManagedObjectModel * managedObjectModel;
@property (nonatomic, assign) NSManagedObjectContext * managedObjectContext;

- (void) showInstances: (NSInteger) row;
@end
