//
//  SongsTabBarController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/20/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#define RECENTS_VIEW 0
#define TOP_VIEW 1
#define VOTES_VIEW 2

#import "SongsTabBarController.h"
#import "TopSongsController.h"
#import "MusicPlayerController.h"
#import "RecentsTableViewController.h"
#import "MyVotesViewController.h"
#import "NoFavoritesViewController.h"

@implementation SongsTabBarController

@synthesize currentView;
@synthesize tabBar;
//@synthesize containerView;
@synthesize recentlyPlayedController;
@synthesize topSongsController;
@synthesize myVotesController;
@synthesize parentNavigationItem;

@synthesize clearAllButton, reloadButton, backButton;
@synthesize wallpaper;

@synthesize noFavoritesViewController;

- (id) initWithNavigationItem: (UINavigationItem *) navItem {
	appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];

	if(self = [self init]) {
		parentNavigationItem = navItem;
	}
	return self;
}

- (void) viewDidAppear: (BOOL) animate {
}

- (void)viewDidLoad {
	[super viewDidUnload];

	appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	UITabBarItem * top = [tabBar.items objectAtIndex:TOP_VIEW];
	
	top.title = NSLocalizedStringFromTable(@"TopRated", @"Tables", nil);
	
	UITabBarItem * pList = [tabBar.items objectAtIndex:RECENTS_VIEW];
	
	pList.title = NSLocalizedStringFromTable(@"Recents", @"Tables", nil);

	self.clearAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Clear", @"Buttons", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(clearAll)];
	self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadData)];
	
	NSString *imgName = [appDelegate.rootViewController.playerDelegate backButtonImageName];
	UIImage * img = [UIImage imageNamed:imgName];
	self.backButton = [[UIBarButtonItem alloc] initWithImage:img style:UIBarButtonItemStyleBordered target:self action:@selector(back)];

	//tabBar.alpha = .25;
	
	[self restore];

}

- (void) restore {
	
	currentTabIndex = [[NSUserDefaults standardUserDefaults] integerForKey:[PlayerEventNotifications keyForStatus:StartupRestoreTabIndex]];
	
	[tabBar addObserver:self forKeyPath:@"selectedItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

	tabBar.selectedItem = [tabBar.items objectAtIndex:currentTabIndex];
	
}

- (void) updateNavigation {

	NSArray * sections = [currentView.fetchedResultsController sections];
	if (sections && [sections count]) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
		rowCount = [sectionInfo numberOfObjects];
	}
	
//	id <NSFetchedResultsSectionInfo> sectionInfo = [[currentView.fetchedResultsController sections] objectAtIndex:0];
//	rowCount = [sectionInfo numberOfObjects];
	
	[parentNavigationItem setLeftBarButtonItem:backButton animated:YES];

	parentNavigationItem.titleView = nil;
	
	switch (currentTabIndex) {
		case RECENTS_VIEW:
			
			if(rowCount == 0) {
				[parentNavigationItem setRightBarButtonItem:reloadButton animated:YES];
			} else {
				[parentNavigationItem setRightBarButtonItem:clearAllButton animated:YES];
			}
			break;
		case TOP_VIEW:
			if(rowCount == 0) {
				[parentNavigationItem setRightBarButtonItem:reloadButton animated:YES];
			} else {
				[parentNavigationItem setRightBarButtonItem:clearAllButton animated:YES];
			}
			
			break;
		case VOTES_VIEW:
			if(rowCount == 0) {
				[parentNavigationItem setRightBarButtonItem:nil animated:YES];
				currentView.tableView.tableHeaderView = self.noFavoritesViewController.view;
			} else {
				[parentNavigationItem setRightBarButtonItem:self.editButtonItem animated:YES];
				currentView.tableView.tableHeaderView = nil;
			}
			break;
		default:
			break;
	}
	
	parentNavigationItem.title = currentView.viewTitle;
	
}
- (IBAction)showView {

	[currentView.view removeFromSuperview];

	switch (currentTabIndex) {
		case RECENTS_VIEW:
			currentView = self.recentlyPlayedController;
			break;
		case TOP_VIEW:
			currentView = self.topSongsController;
			break;
		case VOTES_VIEW:
			currentView = self.myVotesController;
			break;
		default:
			break;
	}
	
	BOOL viewIsLoaded = [currentView isViewLoaded];
	
	UIView * containerView = appDelegate.rootViewController.containerView1;
	
	CGRect frame = CGRectMake(0.0, 0.0, containerView.frame.size.width, tabBar.frame.origin.y);
	
	currentView.view.frame = frame;
	[containerView addSubview:currentView.view];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	switch (currentTabIndex) {
		case RECENTS_VIEW:
			if (!viewIsLoaded) {
				
				NSString * key = [PlayerEventNotifications keyForStatus:AudioStreamerFetchMissedSongs];
				if ([defaults boolForKey:key]) {
					[defaults setBool:NO forKey:key];
					
					[appDelegate.rootViewController performSelector:@selector(startCreateMissedSongs:) withObject:recentlyPlayedController];

				} else {

					[currentView performSelector:@selector(loadData)];

				}
				
			}
			break;
		case TOP_VIEW:
			if (!viewIsLoaded) {
				NSDate * lastTopSongsRefreshDate = [defaults objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsLastFetchDate]];
				
				BOOL  topSongsAreFresh;
				
				if (lastTopSongsRefreshDate == nil) {
					topSongsAreFresh = NO;
				} else {
					topSongsAreFresh = [appDelegate.rootViewController topSongsAreRefreshed:lastTopSongsRefreshDate];
				}
				[defaults setBool:topSongsAreFresh forKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsAreFresh]];
				if (!topSongsAreFresh) {
					// populate topSongs in background
					[appDelegate.rootViewController performSelector:@selector(startCreateTopSongs:) withObject:topSongsController];
				} else {
					[currentView performSelector:@selector(loadData)];
				}
			}
			break;
		case VOTES_VIEW:
			break;
		default:
			break;
	}
	
	[self updateNavigation];
	
}

- (void) enableTabBar: (BOOL) editing {
	self.tabBar.userInteractionEnabled = !editing;
	
	[UIView beginAnimations:@"enableTabBar" context:self.view];
    [UIView setAnimationDuration:0.75];
	self.tabBar.alpha = (editing) ? 0.75 : 1.00;
	[UIView commitAnimations];
	
	[parentNavigationItem setLeftBarButtonItem:((editing) ? clearAllButton : backButton) animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    
	[currentView setEditing:editing animated:animated];
	
	[self enableTabBar:editing];
	
	if (!editing) {
		[self showView];
	}

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)clearAll {

	[currentView performSelector:@selector(clearAll)];
}

-(void) back {
	// update the scroll view to the appropriate page
	//[appDelegate.rootViewController.navigationController setNavigationBarHidden:YES animated:NO];
	appDelegate.rootViewController.pageControl.currentPage = 0;
}

- (void)viewDidUnload {

	[tabBar removeObserver:self forKeyPath:@"selectedItem"];

	self.tabBar = nil;
	//self.containerView = nil;
	
	self.topSongsController = nil;
	self.recentlyPlayedController = nil;
	self.myVotesController = nil;

	self.clearAllButton = nil;
	self.reloadButton = nil;
	self.backButton = nil;
	
	self.wallpaper = nil;
	
	[super viewDidUnload];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"selectedItem"]) {
		
		UITabBarItem * item = [change objectForKey:NSKeyValueChangeNewKey];

		currentTabIndex = item.tag;
		[[NSUserDefaults standardUserDefaults] setInteger:currentTabIndex forKey:[PlayerEventNotifications keyForStatus:StartupRestoreTabIndex]];
		[self showView];
		
    }
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self doClearAll];
	}
}

- (IBAction) loadData {
	
	if (![appDelegate.rootViewController performSelector:@selector(isReachable)]) {
		return;
	}
	
	switch (currentTabIndex) {
		case RECENTS_VIEW:
			// remove table delegate so that chagnes aren't reflected in the table.
			//currentView.fetchedResultsController.delegate = nil;
			[appDelegate.rootViewController performSelector:@selector(startCreateMissedSongs:) withObject:currentView];
			break;
		case TOP_VIEW:
			// remove table delegate so that chagnes aren't reflected in the table.
			//currentView.fetchedResultsController.delegate = nil; // topSongs
			[appDelegate.rootViewController performSelector:@selector(startCreateTopSongs:) withObject:currentView];
			break;
		case VOTES_VIEW:
			break;
		default:
			break;
	}
	
}

- (void) doClearAll {
	[currentView doClearAll];
}
	
- (void)dealloc {
	//	NSLog(@"Tab view dealloc");

	[tabBar release];
	//[containerView release];
	
	[topSongsController release];
	[recentlyPlayedController release];
	[myVotesController release];
	
	[clearAllButton release];
	[reloadButton release];
	[backButton release];
	
	[wallpaper release];
	
    [super dealloc];
}

- (SongPickerView *) topSongsController {
	
    if (topSongsController != nil) {
        return topSongsController;
    }
	
    topSongsController = [[TopSongsController alloc] init];
	topSongsController.pickerViewController = self;
    return topSongsController;
}

- (RecentsTableViewController *) recentlyPlayedController {
	
    if (recentlyPlayedController != nil) {
        return recentlyPlayedController;
    }
	
    recentlyPlayedController = [[RecentsTableViewController alloc] init];
	recentlyPlayedController.pickerViewController = self;
    return recentlyPlayedController;
}

- (MyVotesViewController *) myVotesController {
	
    if (myVotesController != nil) {
        return myVotesController;
    }
	
    myVotesController = [[MyVotesViewController alloc] init];
	myVotesController.pickerViewController = self;
    return myVotesController;
}

- (NoFavoritesViewController *) noFavoritesViewController {
	
    if (noFavoritesViewController != nil) {
        return noFavoritesViewController;
    }
	
    noFavoritesViewController = [[NoFavoritesViewController alloc] init];
    return noFavoritesViewController;
}


@end
