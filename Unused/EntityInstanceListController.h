//
//  EntityInstanceListController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/15/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataEditingTableViewController.h"


@interface EntityInstanceListController : CoreDataEditingTableViewController <CoreDataEditingTableViewDelegate>{

	NSString *titleAttribute, *subTitleAttribute;
	
}

@property (nonatomic, retain) NSString * titleAttribute;
@property (nonatomic, retain) NSString * subTitleAttribute;

@end