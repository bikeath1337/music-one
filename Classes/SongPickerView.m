//
//  SongPickerView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/18/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "SongPickerView.h"
#import "CustomerSongDetailView.h"
#import "MusicPlayerController.h"
#import "PlayerEventNotifications.h"
#import "Song.h"

@implementation SongPickerView

@synthesize pickerViewController;
@synthesize tableType;

- (void)loadView {
	
	UITableView *view = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0,  320.0, 250.0)];
	
	view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight );

	self.coreEditingDelegate = self;
	self.tableView = view;
	
	view.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	view.separatorColor = [UIColor blackColor];
	view.backgroundColor = [UIColor clearColor];
	//view.backgroundColor = [UIColor orangeColor];
	//view.alpha = 0.75;
	view.sectionHeaderHeight = 30.0;
	[view release];
}


- (void) viewDidLoad {
	self.managedObjectContext = appDelegate.managedObjectContext;

	[super viewDidLoad];
	
}

-(void) viewDidUnload {
	[super viewDidUnload];
}

- (void) restoreState {
}

- (void) clearCache {
    if (fetchedResultsController == nil) {
        return;
    }
	[NSFetchedResultsController deleteCacheWithName:self.tblCacheName];
}

- (void) showDetail: (Song *) managedObject animated:(BOOL) animated {
	CustomerSongDetailView *detail = [[CustomerSongDetailView alloc] initWithSong:managedObject];

	detail.canEdit = NO;
	[appDelegate.rootViewController pushViewController:detail animated:animated];
	[detail release];
}

- (void) showDetail: (NSManagedObject *) managedObject forRow:(NSIndexPath *) indexPath {
	[self showDetail:managedObject animated:YES];
}

-(void) clearAll {
	NSString* prompt = [NSString stringWithFormat:NSLocalizedStringFromTable(@"ClearAllFormat", @"Buttons", nil), self.viewTitle];
	
	UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil 
														delegate:self.pickerViewController
											   cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"Buttons", nil)
										  destructiveButtonTitle:prompt
											   otherButtonTitles:nil];
    [sheet showFromToolbar:appDelegate.rootViewController.navigationController.toolbar];
	
	[sheet release];
	
}

- (void) doDelete: (NSManagedObject *) managedObject {
	[managedObjectContext deleteObject:managedObject];
}
			  
- (void) doClearAll {
	// Delete All...
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	if (self.queryPredicate != nil) {
		[request setPredicate:self.queryPredicate];
	}
	
	NSArray * fetchResults = [managedObjectContext executeFetchRequest:request error:&error]; 
	for (NSManagedObject * obj in fetchResults) {
		[self doDelete:obj];
	}
	if (![managedObjectContext save:&error]) {
		if(error != nil) { 
			[appDelegate processError:error];
		} 
	} else {
		[self.pickerViewController setEditing:NO animated:YES];
	}
	
	[request release];
	
	[self.pickerViewController performSelectorOnMainThread:@selector(showView) withObject:nil waitUntilDone:NO];

}

- (void) loadData {
	
	// restore delegate so that table is refreshed
	self.fetchedResultsController.delegate = self;
	
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		[self processError:error];
	}
	[self.tableView reloadData];
	
	[self.pickerViewController performSelectorOnMainThread:@selector(showView) withObject:nil waitUntilDone:NO];
}

- (void) configureTableCell: (UITableViewCell *) cell managedObject: (NSManagedObject *) managedObject {
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[[NSUserDefaults standardUserDefaults] setInteger:indexPath.row forKey:[PlayerEventNotifications keyForStatus:StartupRestoreSongTableSelectedRow]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self doClearAll];
	}
}

- (void) insertNewObject {
}

- (NSString *) tableHeader:(NSInteger) section {
	return @"";
}

- (void) dealloc {
	[super dealloc];
}


@end
