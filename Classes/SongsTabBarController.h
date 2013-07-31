//
//  SongsTabBarController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/20/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TopSongsController;
@class MusicPlayerAppDelegate;
@class SongPickerView;
@class RecentsTableViewController;
@class MyVotesViewController;
@class NoFavoritesViewController;

@interface SongsTabBarController : UIViewController <UIActionSheetDelegate, UINavigationBarDelegate > {
	
	UITabBar * tabBar;
	
	UIBarButtonItem * clearAllButton, * reloadButton, * backButton;

	//UIView * containerView;
	
	MusicPlayerAppDelegate *appDelegate;
	SongPickerView * currentView;
	
	NSInteger currentTabIndex;
	
	TopSongsController *topSongsController;
	RecentsTableViewController * recentlyPlayedController;
	MyVotesViewController * myVotesController;
	
	UINavigationItem * parentNavigationItem;
	//UINavigationBar * navigationBar;
	
	NoFavoritesViewController *noFavoritesViewController;

	NSInteger rowCount;
	
	UIImageView * wallpaper;

}

@property (nonatomic, retain) IBOutlet UIImageView * wallpaper;

@property (nonatomic, assign) SongPickerView *currentView;
@property (nonatomic, retain) UIBarButtonItem *clearAllButton;
@property (nonatomic, retain) UIBarButtonItem *reloadButton;
@property (nonatomic, retain) UIBarButtonItem *backButton;

//@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UITabBar *tabBar;
//@property (nonatomic, retain) IBOutlet UIView *containerView;

@property (nonatomic, retain) TopSongsController *topSongsController;
@property (nonatomic, retain) RecentsTableViewController *recentlyPlayedController;
@property (nonatomic, retain) MyVotesViewController *myVotesController;

@property (assign, nonatomic) NoFavoritesViewController * noFavoritesViewController;
@property (assign, nonatomic) UINavigationItem * parentNavigationItem;

- (id) initWithNavigationItem: (UINavigationItem *) navItem;

- (void) restore;
- (IBAction)showView;
- (IBAction)back;

- (void)clearAll;
- (void)doClearAll;

- (void) updateNavigation;

//- (void) selectTabForIndex:(NSInteger) index;

@end
