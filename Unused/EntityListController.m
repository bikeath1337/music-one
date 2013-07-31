//
//  EntityListController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/15/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "EntityListController.h"
#import "EntityInstanceListController.h"


@implementation EntityListController

@synthesize managedObjectModel;
@synthesize managedObjectContext;

#pragma mark Table view methods

- (void) viewDidLoad {
	self.title = @"Entities";
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.managedObjectModel.entities count];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

	NSEntityDescription *entityDesc = [self.managedObjectModel.entities objectAtIndex:indexPath.row];
    cell.textLabel.text = [entityDesc name];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self showInstances: indexPath.row];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void) showInstances:(NSInteger)row {
	
	EntityInstanceListController *controller = [[EntityInstanceListController alloc] init];
	controller.managedObjectContext = self.managedObjectContext;
	
	NSEntityDescription *entityDesc = [self.managedObjectModel.entities objectAtIndex:row];

	NSString * name = [entityDesc name];

	controller.entityName = name; 
	controller.viewTitle = name;
	controller.entityName = name;
	
	if ([name isEqualToString:@"Station"]) {
		controller.titleAttribute = @"stationName";
		controller.subTitleAttribute = @"stationDescription";
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"stationName" ascending:YES];
		controller.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
		[sortDescriptor release];
	} else if ([name isEqualToString:@"StreamOption"]) {
		controller.titleAttribute = @"contentType";
		controller.subTitleAttribute = @"streamDescription";
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
		controller.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
		[sortDescriptor release];
	} else if ([name isEqualToString:@"Song"]) {
		controller.titleAttribute = @"name";
		controller.subTitleAttribute = @"artist";
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
		controller.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
		[sortDescriptor release];
	} else if ([name isEqualToString:@"RecentlyPlayed"]) {
		controller.titleAttribute = @"timeStamp";
		controller.subTitleAttribute = @"song";
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
		controller.sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
		[sortDescriptor release];
	} else {
		[controller release];
		return;
	}

	controller.canDelete = YES;
	controller.canInsert = YES;
	controller.canChange = YES;
	
	
	controller.navigationController.navigationBarHidden = NO;
	
	[self.navigationController pushViewController:controller animated:YES];
	
    [controller release];
}


- (void)dealloc {
    [super dealloc];
}


@end

