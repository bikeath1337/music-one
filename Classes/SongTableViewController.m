//
//  SongTableViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/20/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "SongPickerView.h"
#import "SongTableViewController.h"
#import "Song.h"


@implementation SongTableViewController


- (void) viewDidLoad {
	
	self.entityName = @"Song";
	
	self.coreEditingDelegate = self;
	//self.canClearAll = YES;
	
	[super viewDidLoad];
}

@end
