//
//  RootViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/04/2010.
//  Copyright Total Managed Fitness 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MusicPlayerController.h"
#import "MusicPlayerAppDelegate.h"
#import "PreferencesController.h"
#import "NowPlayingViewController.h"
#import "RecentlyPlayed.h"
#import "PlayerEventNotifications.h"
#import "SongsTabBarController.h"
#import "PlayerEventNotifications.h"
#import "SongPickerView.h"
#import "BandwidthController.h"
#import "SplashController.h"
#import "Song.h"

static NSUInteger kNumberOfPages = 2;

// Audio session callback function for responding to audio route changes. If playing 
//		back application audio when the headset is unplugged, this callback pauses 
//		playback and displays an alert that allows the user to resume or stop playback.
//
//		The system takes care of iPod audio pausing during route changes--this callback  
//		is not involved with pausing playback of iPod audio.
//
// This function is adapted from Apple's example in AudioSession 
//
void audioRouteChangeListenerCallback (
									   void                      *inUserData,
									   AudioSessionPropertyID    inPropertyID,
									   UInt32                    inPropertyValueSize,
									   const void                *inPropertyValue   ) {
	// This callback, being outside the implementation block, needs a reference to the
	//		the AudioStreamer object, which it receives in the inUserData parameter.
	//		see the call to AudioSessionAddPropertyListener).
	
	MusicPlayerController *player = (MusicPlayerController *) inUserData;
	
	if(player == nil)
		return;
	
	[player handleAudioRouteChange:inPropertyID inPropertyValueSize:inPropertyValueSize inPropertyValue: inPropertyValue];
}

@interface MusicPlayerController ()

- (void)setButtonImage:(NSNumber *)systemItem;
- (void)createStreamer;
- (void)destroyStreamer;

@end

@implementation MusicPlayerController

#if DEBUG_SCREEN
@synthesize playerStatus, buffersUsed; // , consoleView; //, autoLockDisabled;
#endif

@synthesize songsViewController;

@synthesize scrollView, pageControl, pageViewControllers;

@synthesize playerDelegate;
@synthesize userAction;
@synthesize songID, track, bitRate, dataFormat, timePlayed, dataFormatString;

@synthesize playPauseButton;
@synthesize infoButton, bandwidthController;

@synthesize containerView, containerView1;

@synthesize topSongsRefreshDateTemplate;

@synthesize imageViewStop;
@synthesize imageViewPlay;
@synthesize imageViewPause;

@synthesize fetchedResultsController, managedObjectContext;

@synthesize splashController;

@synthesize activityView;

@synthesize nowPlayingSong;
@synthesize appDelegate;

@synthesize currentReach;
@synthesize netStatus;
@synthesize reachable;

@synthesize nowPlayingController;

@synthesize onColor, offColor;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	currentPageNumber = -1;
	
	self.appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];

	[self.navigationController setToolbarHidden:NO animated:NO];
	
	CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
	CGFloat screenWidth = UIInterfaceOrientationIsPortrait((self.interfaceOrientation)) ? screenFrame.size.width : screenFrame.size.height;
	CGFloat screenHeight = UIInterfaceOrientationIsPortrait((self.interfaceOrientation)) ? screenFrame.size.height : screenFrame.size.width;

	[appDelegate addObserver:self forKeyPath:@"active" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

	CGRect toolBarFrame = self.navigationController.toolbar.frame;

	self.pageViewControllers = [[NSMutableArray alloc] initWithObjects:self,[NSNull null],nil];
	
	self.infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	infoButton.frame = CGRectMake(0.0, 0.0, 45.0, infoButton.frame.size.height);
	[infoButton addTarget:self action:@selector(showInfo:) forControlEvents:UIControlEventTouchUpInside];
	
	self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
	activityView.frame = CGRectMake(screenWidth/2 - activityView.frame.size.width/2,350,activityView.frame.size.width,activityView.frame.size.height);
	activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;

	self.playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
	playPauseButton.bounds = CGRectMake(0.0, 0.0, 50.0, 50.0);
	[playPauseButton setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
	[playPauseButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0,0.0,screenWidth,screenHeight-toolBarFrame.size.height)];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	scrollView.contentOffset = CGPointMake(0.0, 0.0);
	scrollView.contentSize = CGSizeMake(screenWidth * kNumberOfPages, scrollView.frame.size.height);
    scrollView.delegate = self;
	scrollView.pagingEnabled = YES;
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.bounces = NO;
	
	[self.view addSubview:scrollView];
	[self.view addSubview:activityView];
	
	CGFloat height = UIInterfaceOrientationIsPortrait((self.interfaceOrientation)) ? 416.0 : 248.0;

	self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,height)];
	containerView.clipsToBounds = YES;
		
	height = UIInterfaceOrientationIsPortrait((self.interfaceOrientation)) ? 380.0 : 236.0;
	self.containerView1 = [[UIView alloc] initWithFrame:CGRectMake(screenWidth,0,screenWidth, height)];
	containerView1.clipsToBounds = YES;

	
	self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(30,containerView.frame.size.height - 36.0,screenWidth - 60.0,36.0)];
    pageControl.numberOfPages = kNumberOfPages;
	pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];

	// MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame: CGRectMake(0.0, 382.0, scrollView.frame.size.width - 22.0, 20.0)];
	MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame: CGRectMake(0.0, 10.0, scrollView.frame.size.width - 10.0, 20.0)];
	//	myVolumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	myVolumeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
	myVolumeView.showsVolumeSlider = NO;
	
	[scrollView addSubview: myVolumeView];
	[myVolumeView release];
	
	showDefaultScreen = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"ShowDefaultScreen"] isEqual:@"YES"];

	if(!showDefaultScreen){
		[scrollView addSubview:pageControl];

	}
	
	[scrollView addSubview:containerView];
	[scrollView addSubview:containerView1];

#if DEBUG_SCREEN

	CGRect frame = pageControl.frame;
	frame.size.width = 120.0;
	frame.origin.x = pageControl.frame.size.width - frame.size.width - 5.0;
	self.playerStatus = [[UILabel alloc] initWithFrame:frame];
	playerStatus.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	playerStatus.font = [UIFont boldSystemFontOfSize:10.0]; 
	playerStatus.backgroundColor = [UIColor clearColor];
	playerStatus.textAlignment = UITextAlignmentRight;
	playerStatus.text = @"Startup";

	[scrollView addSubview:playerStatus];
	
	frame = pageControl.frame;
	frame.origin.y -= 36.0;
	self.buffersUsed = [[UILabel alloc] initWithFrame:frame];
	buffersUsed.font = [UIFont boldSystemFontOfSize:12.0]; 
	buffersUsed.backgroundColor = [UIColor clearColor];
	buffersUsed.textColor = [UIColor whiteColor];
	buffersUsed.textAlignment = UITextAlignmentCenter;
	buffersUsed.text = @"0";
	
	[scrollView addSubview:buffersUsed];

#endif
	
	currentSystemItem = UIBarButtonSystemItemPlay;
	[self setButtonImage:[NSNumber numberWithInt:UIBarButtonSystemItemPlay]];
	
	//
	// Set the audio session category so that we continue to play if the
	// iPhone/iPod auto-locks.
	//
	audioSession = [AVAudioSession sharedInstance];
	
	NSError *error = nil;
	[audioSession setCategory:AVAudioSessionCategoryPlayback error:(NSError **)error];
	[audioSession setActive:YES error: &error];
	[audioSession setDelegate:self]; 
	currentAudioSessionOutputChannels = audioSession.currentHardwareOutputNumberOfChannels;
	// Registers the audio route change listener callback function (removing headphones)
	AudioSessionAddPropertyListener (
									 kAudioSessionProperty_AudioRouteChange,
									 audioRouteChangeListenerCallback,
									 self
									 );
	
	self.title = NSLocalizedStringFromTable(@"Station Name", @"Owner", nil);

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerFetchMissedSongs]];
	
	NSDate * lastCleanupDate = [defaults objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerLastCleanupDate]];
	if (lastCleanupDate == nil) { // never cleaned up, so assume we cleaned up today
		[defaults setObject:[NSDate date] forKey:[PlayerEventNotifications keyForStatus:AudioStreamerLastCleanupDate]];
	} else {
		// weekly cleanup
		NSTimeInterval intervalSinceLastClean = -[lastCleanupDate timeIntervalSinceNow];
		
		if (intervalSinceLastClean >= WEEK_IN_SECONDS) {
			[self performSelectorInBackground:@selector(songCleanup) withObject:nil];
		}
	}
	
	// Vote cleanup
	NSString *key = [PlayerEventNotifications keyForStatus:AudioStreamerLastVoteCleanupDate];
	NSDate * lastVoteCleanupDate = [defaults objectForKey:key];

	//NSLog(@"set lastvotecleanupdate to NIL");;
	if (lastVoteCleanupDate == nil) {
		lastVoteCleanupDate = [playerDelegate voteClearDate];
		[defaults setObject:lastVoteCleanupDate forKey:key];
	} else {
		
		NSTimeInterval offset = [[NSDate date] timeIntervalSinceDate:lastVoteCleanupDate]; 
		if (offset >= WEEK_IN_SECONDS) {
			// time to clear votes -- this slows app loading but it needs to be done on the main thread and only 1x per week
			[self voteCleanup];
		} else {
			lastVoteCleanupDate = [playerDelegate voteClearDate];
			
			NSDate * nextVotingStart =  [lastVoteCleanupDate dateByAddingTimeInterval:WEEK_IN_SECONDS]; // 1 week after the last voting 
			NSTimeInterval clearVotesAfterSecondsPassed =  [nextVotingStart timeIntervalSinceNow];
			
			// Perform the cleanup if the app is still running
			[self performSelector:@selector(voteCleanup) withObject:nil afterDelay:clearVotesAfterSecondsPassed+1];
			
		}

	}
	
	nowPlayingCount = NSNotFound;
	
	self.currentReach = [Reachability reachabilityForInternetConnection];
	[currentReach startNotifer];
	[currentReach addObserver:self forKeyPath:@"reachable" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	
	self.reachable = !([currentReach currentReachabilityStatus] == NotReachable);

}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	NSError *error = nil;
	[audioSession setActive:NO error: &error];

	[nowPlayingController release];
	
	[currentReach removeObserver:self forKeyPath:@"reachable"];
	[currentReach stopNotifer];
	[appDelegate removeObserver:self forKeyPath:@"active"];

	self.playPauseButton = nil;
	self.fetchedResultsController = nil;
	self.managedObjectContext = nil;
	
	self.splashController = nil;
	
	self.containerView = nil;
	self.containerView1 = nil;
	self.track = nil;
	self.bitRate = nil;
	self.timePlayed = nil;
	
	self.imageViewStop = nil;
	self.imageViewPlay = nil;
	self.imageViewPause = nil;
	
	self.activityView = nil;
	self.bandwidthController = nil;
	
	self.onColor = nil;
	self.offColor = nil;
	
#if DEBUG_SCREEN
	self.playerStatus = nil;
	self.buffersUsed = nil;
#endif
}

- (void)didReceiveMemoryWarning {
	UIViewController *controller = [pageViewControllers objectAtIndex:1];
	
	if ((NSNull *) controller != [NSNull null]) {
		// Songs view may be loaded and visible
		// if it is not visible, then 
		if(pageControl.currentPage == 0) {
			// this action should trigger the release of the Songs view controller
			if(controller.isViewLoaded) {
				[controller.view removeFromSuperview];
				[self.pageViewControllers replaceObjectAtIndex:1 withObject:[NSNull null]];
			}
		}
	}
	
    [super didReceiveMemoryWarning];
}

- (void)dealloc {

	[pageViewControllers release];
    [scrollView release];
    [pageControl release];
	
	[containerView release];
	[containerView1 release];
	
	[playPauseButton release];
	
	if (progressUpdateTimer)
	{
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
	}
	
	[splashController release];

	[streamer release];
	
	[fetchedResultsController release];
	[managedObjectContext release];
	
	[track release];
	[bitRate release];
	[timePlayed release];
	
	[imageViewStop release];
	[imageViewPlay release];
	[imageViewPause release];
	
	[activityView release];
	
	[bandwidthController release];
	
	[onColor release];
	[offColor release];
	
#if DEBUG_SCREEN
	[playerStatus release];
	[buffersUsed release];
#endif
	
	[super dealloc];
}

- (void) restore {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[pageControl addObserver:self forKeyPath:@"currentPage" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	NSInteger pg = [defaults integerForKey:[PlayerEventNotifications keyForStatus:StartupRestoreScrollPage]];

	BOOL wasPlaying = [defaults boolForKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
	
	wasPlaying = (wasPlaying && self.reachable);
	
	userAction = ASC_STOPPLAY;
	
	[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
		
	pageControl.currentPage = pg;

	if (pg == 0 && wasPlaying) {
		[self activityAnimationStart:YES];
	}
	if(!showDefaultScreen) {
		[self updateToolbar:NO];
	}
	
	[playerDelegate customizeNavigationController:self.navigationController];
	[playerDelegate customizeStartupView];

	[self updateNavigation:NO];

	BOOL showPreferences = [defaults boolForKey:[PlayerEventNotifications keyForStatus:StartupRestoreShowingPreferences]];

	if (pg == 1) {
		NSArray *  savedNavigationStack = [appDelegate savedNavigationStack];
		
		if (!showPreferences && [savedNavigationStack count]) {
			for (NSString * className in savedNavigationStack) {
				if ([className isEqual:@"CustomerSongDetailView"]) {
					NSString * songIDx = [[NSUserDefaults standardUserDefaults] objectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreDetailSongID]];
					
					Song * song = [appDelegate findSong:songIDx];
					if(song != nil) {
						self.view.hidden = YES;
						songsViewController = [pageViewControllers objectAtIndex:1];
						[songsViewController.currentView showDetail:song animated:NO];
						
					}
				}
			}
		}
	}

	if(showPreferences) {
		self.view.hidden = YES;
		[self showInfoView:NO];
		
	}
	
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(batteryStateDidChange:)
												 name:UIDeviceBatteryStateDidChangeNotification object:nil];
	[self performSelector:@selector(batteryStateDidChange:) withObject:nil];
	
	if (wasPlaying && self.reachable) { // resume playing because app was interrupted by a phone call or other interruption
		[self performSelector:@selector(start) withObject:nil afterDelay:0.5];
	} else {
		[self activityAnimationStart:NO];
	}
	
	changingOrientation = NO;

}

#pragma mark -
#pragma mark Page Swipe Management

- (IBAction)changePage:(id)sender {
    int page = pageControl.currentPage;
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)

    [self loadScrollViewWithPage:page];
	if(!page && !appDelegate.restoringState) {
		[self loadScrollViewWithPage:1];
	}
	
    // update the scroll view to the appropriate page
	CGRect frame = CGRectMake(scrollView.frame.size.width*page, 0, scrollView.frame.size.width, scrollView.frame.size.height);
	
	[scrollView scrollRectToVisible:frame animated:(!appDelegate.restoringState)];
	
    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    scrollUsed = NO;
}

- (void)loadScrollViewWithPage:(int)page {

	if (page >= kNumberOfPages) return;
	
    // replace the placeholder if necessary
    UIViewController *controller = [pageViewControllers objectAtIndex:page];

	CGRect scrollFrame = scrollView.frame;
	scrollFrame.origin.x = page*scrollFrame.size.width;	

	if(!changingOrientation && page == 0) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		BOOL wasPlaying = (userAction == ASC_STARTPLAY) || [defaults boolForKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];

		UIViewController * page0ViewController = (wasPlaying) ?
			self.nowPlayingController :
			self.splashController;

		UIView * page0View = page0ViewController.view;

		UIView * visibleView = ([containerView.subviews count]) ? [containerView.subviews objectAtIndex:0] : nil;
		
		if (![visibleView isEqual:page0View]) {
			[visibleView removeFromSuperview];
		} else {
			// nothing to change
			return;
		}

		[containerView addSubview:page0View];

		[scrollView addSubview:containerView];
		[scrollView sendSubviewToBack:containerView];
		[scrollView bringSubviewToFront:pageControl];
		
	} else if (page && (NSNull *) controller == [NSNull null]) {

		songsViewController = [[SongsTabBarController alloc] initWithNavigationItem:self.navigationItem];
		songsViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self.pageViewControllers replaceObjectAtIndex:1 withObject:songsViewController];
		[songsViewController release];
		
		UITabBar * tabBar = songsViewController.tabBar;

		CGRect frame = tabBar.frame;
		
		frame.origin.y = containerView1.frame.size.height - tabBar.frame.size.height;
		frame.size.width = containerView1.frame.size.width;
		
		tabBar.frame = frame;
		
		[containerView1 addSubview:songsViewController.wallpaper];
		[containerView1 addSubview:tabBar];
	}
	
}

#pragma mark -
#pragma mark UIScrollView Management

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;

    // Switch the indicator when more than 50% of the previous/next page is visible
	if(!changingOrientation) {
		scrollUsed = YES;
		pageControl.currentPage = page;
	}
	// load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
	[self loadScrollViewWithPage:page];
	if(!page) {
		[self loadScrollViewWithPage:1];
	}
	
}

- (void) updateNavigation:(BOOL) animated {
	if (pageControl.currentPage) {

		[self.navigationController setNavigationBarHidden:NO animated:animated];
		
		[songsViewController updateNavigation];

	} else {
		self.navigationItem.titleView = nil;
		self.navigationItem.title = self.title;
		[self.navigationItem setRightBarButtonItem:nil animated:animated];
		[self.navigationItem setLeftBarButtonItem:nil animated:animated];

		[self.navigationController setNavigationBarHidden:YES animated:animated];

	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:pageControl.currentPage forKey:[PlayerEventNotifications keyForStatus:StartupRestoreScrollPage]];

}

- (void) updateToolbar:(BOOL) animated {
	
	static UIBarButtonItem * leftButton;

	UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem *iButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:playPauseButton];
	
	UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	self.bandwidthController = [[BandwidthController alloc] init];

	leftButton = [[UIBarButtonItem alloc] initWithCustomView:bandwidthController.view];
	bandwidthController.view.hidden = YES;
	
	[self setToolbarItems:[NSArray arrayWithObjects:leftButton, flex1, barButton, flex2, iButton, nil] animated:animated];
	
	[flex1 release];
	[leftButton release];
	[iButton release];
	[barButton release];
	[flex2 release];
	
	
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	[self updateNavigation:YES];
	
	[self adjustContainerViews:[self interfaceOrientation]];

}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollVw {
    scrollUsed = YES;
	pageControl.currentPage = (scrollVw.contentOffset.x == 0) ? 0 : 1;

	if (pageControl.currentPage) {
		
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		
		[songsViewController updateNavigation];
		
	} else {
		[self updateNavigation:YES];
	}	

	[self adjustContainerViews:[self interfaceOrientation]];
}

-(void) pushViewController: (UIViewController *) controller animated:(BOOL) animated {
	[self.navigationController pushViewController:controller animated:animated];
}

#pragma mark -
#pragma mark UIInterfaceOrientation Management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(!appDelegate.restoringState && self.view.superview != nil ){
		changingOrientation = YES;
	}
    return YES;
}

- (void) adjustContainerViews:(UIInterfaceOrientation)toInterfaceOrientation {
	
	BOOL isPortrait = UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
	
	CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
	CGFloat screenWidth = (isPortrait) ? screenFrame.size.width : screenFrame.size.height;
	CGFloat screenHeight = (isPortrait) ? screenFrame.size.height : screenFrame.size.width;
	
	scrollView.contentSize = CGSizeMake(screenWidth * kNumberOfPages, screenHeight - self.navigationController.toolbar.frame.size.height);
	
	CGFloat height = (isPortrait) ? 416.0 : 268.0;
	
	containerView.frame = CGRectMake(0.0, 0.0, screenWidth, height);
	
	height = (isPortrait) ? 372.0 : 236.0;

	containerView1.frame = CGRectMake(screenWidth, 0.0, screenWidth, height);
	
	scrollView.contentOffset = CGPointMake(screenWidth * pageControl.currentPage, 0);

	scrollView.frame = CGRectMake(0.0,0.0,screenWidth,scrollView.contentSize.height);

	[splashController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:0.0];
	[nowPlayingController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:0.0];

	[songsViewController showView];

}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[self adjustContainerViews:toInterfaceOrientation];
	
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

	if (!appDelegate.active) {
		return;
	}

	changingOrientation = NO;

}

#pragma mark -
#pragma mark UINavigationController delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	
	if (!appDelegate.restoringState && [viewController isEqual:self]) {
		
		[self.navigationController setToolbarHidden:NO animated:YES];

		[self updateNavigation:NO];
		
		[self adjustContainerViews:[self interfaceOrientation]];

		if (currentPageNumber != -1 && currentPageNumber != pageControl.currentPage) {
			NSLog(@"Page !=%d", pageControl.currentPage);
			pageControl.currentPage = currentPageNumber;
		}
		
		self.view.hidden = NO;
		
	} else {
		currentPageNumber = pageControl.currentPage;
	}
	
	[viewController viewWillAppear:animated];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {

	if (!appDelegate.restoringState && [viewController isEqual:self]) {

	} else {
		// SongDetailView
		[self.navigationController setToolbarHidden:YES animated:YES];
	}

	[viewController viewDidAppear:animated];
}



#pragma mark -
#pragma mark Button Management

//
// buttonPressed:
//
// Handles the play/stop button. Creates, observes and starts the
// audio streamer when it is a play button. Stops the audio streamer when
// it isn't.
//
// Parameters:
//    sender - normally, the play/stop button.
//
- (IBAction)buttonPressed:(id)sender
{

	if (currentSystemItem == UIBarButtonSystemItemPlay )
	{
		[self start];	
		
	}	else 
	{
		[self stop];
	}

	
}

- (void) start {
	if (![self performSelector:@selector(isReachable)]) {
		return;
	}
	
	userAction = ASC_STARTPLAY;
	errorCount = 0;
	[self setButtonImage:[NSNumber numberWithInt:UIBarButtonSystemItemStop]];
	[self createStreamer];
}

- (void) stop {
	userAction = ASC_STOPPLAY;
	
	[self destroyStreamer];
	
	[self hideBandwidth:YES];
	[self showSplash];
	[self setButtonImage:[NSNumber numberWithInt:UIBarButtonSystemItemPlay]];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
	self.songID = nil;

}

- (void) restart {
	
	[self destroyStreamer];
	
	errorCount = 0;

	[self createStreamer];
	
}

- (void) activityAnimationStart:(BOOL) start {
	CATransition *transition = [CATransition animation];
	transition.duration = 0.50;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
	[activityView.layer addAnimation:transition forKey:nil];
	
	if(start) {
		[activityView startAnimating];
	} else {
		[activityView stopAnimating];
	}

}

- (void)setButtonImage:(NSNumber *)systemItem
{
	NSUInteger newValue = [systemItem intValue];
	
	if(currentSystemItem == newValue)
		return;

	// Image to flip to
	UIImageView *iv;
	// just flip the the button unless flipping from/to the Stop image
	UIView *flipView = self.playPauseButton;
	if (currentSystemItem == UIBarButtonSystemItemStop || newValue == UIBarButtonSystemItemStop) {
		// just flip the image inside the button when showing or hiding the Stop image
		flipView = self.playPauseButton.imageView;
	}
	
	switch (newValue) {
		case UIBarButtonSystemItemPlay: {
			[self activityAnimationStart:NO];

			iv = self.imageViewPlay;
			break; }
		case UIBarButtonSystemItemStop:
			iv = self.imageViewStop;
			break;
		case UIBarButtonSystemItemPause: {
			[self activityAnimationStart:NO];
			iv = self.imageViewPause;
			break; }
		default:
			break;
	}

	currentSystemItem = newValue;

	[UIView beginAnimations:@"buttonFlip" context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:flipView cache:YES];
	[self.playPauseButton setImage:iv.image forState:UIControlStateNormal];
	[UIView commitAnimations];
	
}

#pragma mark -
#pragma mark Responding to Status Changes of AudioStreamer
/*
- (void) nslog: (NSString *) msg {
	NSString * t = [consoleView.text stringByAppendingString:@"\n"];
	consoleView.text = [t stringByAppendingString:msg];
}
*/
- (void) dummyFail {
	NSMutableDictionary *userInfo;
	NSInteger code;
	userInfo = [NSMutableDictionary dictionary];
	code = -1004;
	
	[userInfo setObject:[NSNumber numberWithBool:NO] forKey:NSUnderlyingErrorKey];
	[userInfo setObject:@"Dummy" forKey:NSStringEncodingErrorKey];
	
	NSError *err = [NSError errorWithDomain:@"com.bikeath1337.streamer.ErrorDomain" code:code userInfo:userInfo];
	
	[streamer connection:nil didFailWithError:err];
	
}
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"track"]) {
		
		if (streamer.state != AS_PLAYING) {
			return;
		}
		//		NSLog(@"State = %@", [AudioStreamer stringForState:streamer.state]);

		if( ![[change objectForKey:NSKeyValueChangeNewKey] isEqualToString:[change objectForKey:NSKeyValueChangeOldKey]]) {
			
			[self performSelectorOnMainThread:@selector(changeTrack:) withObject:[change objectForKey:NSKeyValueChangeNewKey] waitUntilDone:NO];
			
		}
		
    } else if ([keyPath isEqual:@"state"]) {

		NSNumber *newValue = (NSNumber *) [change objectForKey:NSKeyValueChangeNewKey];

#if DEBUG_SCREEN
		[playerStatus performSelectorOnMainThread:@selector(setText:) withObject:[AudioStreamer stringForState:[newValue intValue]] waitUntilDone:NO];
#endif
		
		switch ([newValue integerValue]) {
			case AS_INITIALIZED:
				if(userAction == ASC_STARTPLAY && self.reachable) {
					[self performSelectorOnMainThread:@selector(restart) withObject:nil waitUntilDone:NO];
				}
				break;
			case AS_STARTING_FILE_THREAD:
			case AS_WAITING_FOR_DATA:
			case AS_WAITING_FOR_QUEUE_TO_START:
			case AS_BUFFERING:
				[self performSelectorOnMainThread:@selector(setButtonImage:) withObject:[NSNumber numberWithInt:UIBarButtonSystemItemStop] waitUntilDone:NO];
				[self performSelectorOnMainThread:@selector(startNetworkActivity) withObject:nil waitUntilDone:YES];
				break;
			case AS_STOPPING:
				break;
			case AS_STOPPED:
				
				[progressUpdateTimer invalidate];
				progressUpdateTimer = nil;

				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
				
				switch (streamer.stopReason) {
					case AS_STOPPING_USER_ACTION:
						break;
					case AS_STOPPING_AUDIO_ROUTE_CHANGE:

						[self stop];

						break;
					case AS_NOTREACHABLE_ERROR:
					case AS_URLHOST_ERROR:
					case AS_STOPPING_USER_RESTART:
					case AS_STOPPING_ERROR:
					case AS_URLTIMEOUT_ERROR:
						
						if(userAction == ASC_STARTPLAY && self.reachable) {
							[self performSelectorOnMainThread:@selector(restart) withObject:nil waitUntilDone:NO];
						}
						
						break;
					default:
						break;
				}

				break;
			case AS_PLAYING:
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerFetchMissedSongs]];
				[self performSelectorOnMainThread:@selector(setButtonImage:) withObject:[NSNumber numberWithInt:UIBarButtonSystemItemPause] waitUntilDone:NO];
				[self performSelectorOnMainThread:@selector(changeTrack:) withObject:streamer.streamTitle waitUntilDone:NO];

				//[self performSelector:@selector(dummyFail) withObject:nil afterDelay:1.5];

				break;
			default:
				break;
		}
		
	} else if ([keyPath isEqual:@"currentPage"]) {
		if (!scrollUsed) {
			[self changePage:nil];
		}
		scrollUsed = NO;
    } else if ([keyPath isEqual:@"bitRateString"]) {
		if( ![[change objectForKey:NSKeyValueChangeNewKey] isEqualToString:[change objectForKey:NSKeyValueChangeOldKey]]) {
			[self performSelectorOnMainThread:@selector(updateBitRate:) withObject:[change objectForKey:NSKeyValueChangeNewKey] waitUntilDone:NO];
		}
    } else if ([keyPath isEqual:@"dataFormat"]) {
		
		if( ![[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[change objectForKey:NSKeyValueChangeOldKey]]) {
			UInt32 val = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
			[self performSelectorOnMainThread:@selector(updateDataFormat:) withObject:[AudioStreamer stringForFormatID:val] waitUntilDone:NO];
		}
#if DEBUG_SCREEN
	} else if ([keyPath isEqual:@"bufferCount"]) {
		[buffersUsed performSelectorOnMainThread:@selector(setText:) withObject:[[change objectForKey:NSKeyValueChangeNewKey] stringValue] waitUntilDone:NO];
#endif
	} else if ([keyPath isEqual:@"reachable"]) {
		
		BOOL oldReach = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
		BOOL reach = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		self.reachable = reach;
		//NSLog(@"Music Player is now %@", reach ? @"reachable" : @"unreachable");
		
		if (oldReach && reach) { // reach changed to another, better or worse reachable connection
			return;
		} else if (reachable) {

			// internet dropped while playing, but now we are connected again, so start playing again.

			if (userAction == ASC_STARTPLAY) {
				[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
			}

		} else { // not reachable
			[self performSelectorOnMainThread:@selector(startNetworkActivity) withObject:nil waitUntilDone:NO];
			[self performSelectorOnMainThread:@selector(setButtonImage:) withObject:[NSNumber numberWithInt:UIBarButtonSystemItemStop] waitUntilDone:NO];
		}
		
	} else if ([keyPath isEqual:@"active"]) {
		if (userAction != ASC_STARTPLAY)
			return;

		BOOL newIsActive = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (newIsActive) {
			if (![nowPlayingController isViewLoaded]) {
				[self announceToNowPlayingControllers];
			}
		} else {
			if([nowPlayingController isViewLoaded] && ([appDelegate getApplicationState] == UIApplicationStateInactive)) {
				[nowPlayingController.view removeFromSuperview];
				nowPlayingController.view = nil;
				self.nowPlayingController = nil;
			}
		}

	}
}

- (void)handleStreamerError:(NSError *)error {
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"handleStreamerError can only be done on the main thread.");
	
	if(error != nil) {
		NSLog(@"Error Code=%d, domain=%@", [error code], [error domain]);
		NSLog(@"Description=%@", [error localizedDescription]);
		NSLog(@"Reason=%@", [error localizedFailureReason]);
		NSLog(@"Recovery Suggestion=%@", [error localizedRecoverySuggestion]);
	}

	NSNumber *retry = [error.userInfo objectForKey:NSUnderlyingErrorKey];
	
	if([retry boolValue]) {
		
		errorCount++;
		if (errorCount < ASVC_MAXERRORS ) { 
			NSLog(@"Retrying...count=%d",errorCount);
			
			NSTimeInterval delay = 1.0;
			// increase delay time for the first few errors
			switch (errorCount) {
				case 1:
					delay = 0.1;
					break;
				case 2:
					delay = 0.5;
					break;
				case 3:
				case 4:
					delay = 1.5;
					break;
				case 5:
				case 6:
					delay = 2.5;
					break;
				case 7:
				case 8:
					delay = 3.5;
					break;
				default:
					delay = OTHER_ERROR_RETRY_SECONDS;
					break;
			}

			if ( userAction == ASC_STARTPLAY && ([appDelegate getApplicationState] != UIApplicationStateInactive)) {
				[self performSelector:@selector(createStreamer) withObject:nil afterDelay:delay];
			}

			return;
		}
		
		NSLog(@"Error retries max=%d, count=%d", ASVC_MAXERRORS, errorCount);
	} else {
		//		NSLog(@"not retrying");
	}
	
	errorCount = 0;
	
	UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:[[error localizedDescription] capitalizedString]
														delegate:self 
											   cancelButtonTitle: NSLocalizedStringFromTable(@"Stop", @"Buttons", nil) 
										  destructiveButtonTitle: NSLocalizedStringFromTable(@"Retry", @"Buttons", nil)
											   otherButtonTitles:nil];
	
	[sheet showInView:self.navigationController.topViewController.view];
	
	[sheet release];
	
	[self stop];
}


- (void) updateBitRate: (NSString *) bitrate {
	bitrate = [bitrate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	bandwidthController.bitRateLabel.text = [bitrate stringByAppendingString:NSLocalizedStringFromTable(@"KBS", @"App", nil)
];
}
- (void) updateDataFormat: (NSString *) format {
	bandwidthController.formatLabel.text = format;
	[self hideBandwidth:NO];
	
}

- (void) hideBandwidth:(BOOL) hidden {
	CATransition *transition = [CATransition animation];
	transition.duration = 1.00;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
	bandwidthController.view.hidden = hidden;
	[bandwidthController.view.layer addAnimation:transition forKey:nil];
}

- (void) showSplash {
	[playerDelegate showSplash];
}
- (void) announceToNowPlayingControllers {

	if (pageControl.currentPage == 0) {
		[self.nowPlayingController newSongPlaying:nowPlayingSong];
	} else {
		[self.nowPlayingController setSong:nowPlayingSong];
	}
	
	if(self.reachable) {
		UInt32 delay = arc4random() % FULLSONGNAME_QUERY_DELAY_MAX;
		[self performSelector:@selector(startBackgroundSongFetch) withObject:nil afterDelay:delay];
	}
}


-(void)changeTrack:(NSString *)titleInfoFromAudioStream {
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"changeTrack can only be done on the main thread.");

	if ([titleInfoFromAudioStream length] == 0) {
		return;
	}
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];

	Song * newSong = [playerDelegate createSong:titleInfoFromAudioStream];
	
	if(newSong == nil ){
		NSLog(@"Now playing song could not be created.");
		return;
	}
	
	self.songID = [[newSong valueForKey:@"songID"] stringValue];
	self.track = [newSong valueForKey:@"name"];
	
	[self addRecentlyPlayedSong:newSong];
	
	self.nowPlayingSong = newSong;
	
//	if(appDelegate.active) {
	[self announceToNowPlayingControllers];
//	}	
}

- (void) startBackgroundSongFetch {
	[self performSelectorInBackground:@selector(getFullSongDataBackground) withObject:nil];
}

- (void) getFullSongDataBackground {
	NSAssert(![[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"getFullSongDataBackground cannot be called on the main thread.");
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSDate * lastRefreshed = [self.nowPlayingSong valueForKey:@"lastRefresh"];
	//	NSInteger secs = -[lastRefreshed timeIntervalSinceNow];
	if (lastRefreshed == nil || -[lastRefreshed timeIntervalSinceNow] > DAY_IN_SECONDS) {
		// Data is stale, refresh it
		NSURL *url = [NSURL URLWithString:[playerDelegate songDataURL:[self.nowPlayingSong valueForKey:@"songID"]]];
		
		NSError *error = nil;
		NSString *songData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
		if ([songData length]){
			
			NSDictionary * songDict = [playerDelegate songDictionaryFromString:songData processMissed:NO];
			if(songDict != nil){
				// Now pass the dictionary to the main thread so it can be applied to the managed object in a thread-safe manner
				[self performSelectorOnMainThread:@selector(updateNowPlayingSongWithDictionary:) withObject:songDict waitUntilDone:NO];
			}
			
		}
	}
	
	[pool release];
}

- (void) updateNowPlayingSongWithDictionary: (NSDictionary *) songDict {
	
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"updateNowPlayingSongWithDictionary can only be called on the main thread.");
	
	[self songFromDictionary:songDict processMissed:NO];
	// trigger update so that the Recents table shows the new data
	[currentRecentlyPlayed setValue:[NSNumber numberWithBool:NO] forKey:@"missed"];
	
	NSError * error = nil;
	if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
		if(error != nil) { 
			[appDelegate processError:error];
			return;
		} 
	}
}

- (Song *) songFromDictionary:(NSDictionary *) songDataDict processMissed:(BOOL) processMissed{
	
	NSString * newSongID = [songDataDict objectForKey:@"songID"];
	if ([newSongID intValue] == 0) {
		return nil; // song not found. Song must have a positive int ID
	}
	
	Song * song = [appDelegate findSong:newSongID];
	
	if (song == nil) { // create it
		song = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:managedObjectContext];
		[song setValue:appDelegate.theStation  forKey:@"station"];
		[song setValue:[NSDate date]  forKey:@"addedOnTimestamp"];
	}
	
	// Update the song, assuming that the most recently delivered song is the correct one
	
	[song setValue:[NSNumber numberWithInt:[newSongID intValue]] forKey:@"songID"];
	
	NSString *val = [[songDataDict valueForKey:@"name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *nameOfSong = [song valueForKey:@"name"];
	
	if ([val length]) {
		[song setValue:val forKey:@"name"];
	} else {
		if ([nameOfSong length] == 0) {
			[song setValue:NSLocalizedStringFromTable(@"Missing Song Name", @"Errors", nil) forKey:@"name"];
		}
	}
	
	[song setValue:[songDataDict valueForKey:@"mix"] forKey:@"mix"];
	
	if ([songDataDict objectForKey:@"artist"] != nil) {
		[song setValue:[[songDataDict valueForKey:@"artist"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] forKey:@"artist"];
	} else {
		[song setValue:@"" forKey:@"artist"];
	}
	
	if (processMissed) {
		[song setValue:[songDataDict objectForKey:@"missedDate"] forKey:@"missedDate"];
	}
	
	[song setValue:[NSDate date] forKey:@"lastRefresh"];
	
	// NSLog(@"Song ID=%@, name=%@, artist=%@, mix=%@", [song valueForKey:@"songID"], [song valueForKey:@"name"], [song valueForKey:@"artist"], [song valueForKey:@"mix"]);
	
	return song;
}

- (void) endStream {

	[self destroyStreamer];

	[self setButtonImage:[NSNumber numberWithInt:UIBarButtonSystemItemPlay]];
	[self hideBandwidth:YES];

}

- (Song * ) getNowPlayingSong: (NSString *) newSongID trackName: (NSString *) songName {

	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"getNowPlayingSong can only be done on the main thread.");

	Song * song = [appDelegate findSong:newSongID];
	
	if (song == nil) { // create it
		song = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:managedObjectContext];
		//NSLog(@"now playing song created new song");
		[song setValue:[NSNumber numberWithInt:[newSongID intValue]] forKey:@"songID"];
		[song setValue:songName forKey:@"name"];
		[song setValue:songName forKey:@"fullSongName"];
		[song setValue:appDelegate.theStation  forKey:@"station"];
		[song setValue:[NSDate date]  forKey:@"addedOnTimestamp"];
	}
	
	NSError *error = nil;
	if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
		if(error != nil) { 
			[appDelegate processError:error];
			song = nil;
		} 
	}
	return song;
}

- (NSManagedObject *) addRecentlyPlayedSong: (NSManagedObject *) song {
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"addRecentlyPlayingSong can only be done on the main thread.");

	// see if song has been recently played
	NSSet * recentPlays = [song valueForKey:@"recentlyPlayed"];
	
	BOOL add = YES;
	do {
		if ([recentPlays count]) {
			// find a reccently played song
			
			 NSCalendar *gregorian = [NSCalendar currentCalendar];
			if (gregorian == nil) {
				gregorian = [NSCalendar currentCalendar];
			}
			
			NSDate *now = [NSDate date];
			NSDateComponents *nowComponents =[gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:now];
			NSDateComponents *nowTimeComponents =[gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:now];
			NSDateComponents *dateComponents, *dateTimeComponents;
			
			NSDate *startOfNow = [gregorian dateFromComponents:nowComponents];
			
			for (NSDate * playedOn in recentPlays) {
				NSDate * timeStamp = [playedOn valueForKey:@"timeStamp"];
				dateComponents =[gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:timeStamp];
				
				NSDate *startOfDate = [gregorian dateFromComponents:dateComponents];
				
				NSTimeInterval secs = [startOfNow timeIntervalSinceDate:startOfDate];
				if (secs == 0) { // check time
					NSDate *startOfTimeNow = [gregorian dateFromComponents:nowTimeComponents];
					dateTimeComponents =[gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:timeStamp];
					NSDate *startOfTimeDate = [gregorian dateFromComponents:dateTimeComponents];
					secs = [startOfTimeNow timeIntervalSinceDate:startOfTimeDate];
					if(secs <= 900) { // withing 15 minutes
						add = NO;
						break;
					}
				}
			}
		}
		
		if(add) {
		
			[song setValue:[NSNumber numberWithBool:NO] forKey:@"missed"];
		
			currentRecentlyPlayed = [NSEntityDescription insertNewObjectForEntityForName:@"RecentlyPlayed" inManagedObjectContext:managedObjectContext];
			[currentRecentlyPlayed setValue:[NSDate date] forKey:@"timeStamp"];
			[currentRecentlyPlayed setValue:[NSNumber numberWithBool:NO] forKey:@"missed"];
		
			[song performSelector:@selector(addRecentlyPlayedObject:) withObject:currentRecentlyPlayed];
		}
		
		NSError *error = nil;
		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			if(error != nil) { 
				[appDelegate processError:error];
				song = nil;
			} 
		}
		
	} while (NO);
	
	if(	nowPlayingCount != NSNotFound ) {
		
		nowPlayingCount++;
	}	

	[self performSelectorInBackground:@selector(cleanUpNowPlayingList) withObject:nil];

	return song;
}

#pragma mark -
#pragma mark Voting Tools

-(void) voteRecorded:(NSArray *) args {
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"voteRecorded can only be done on the main thread.");
		
		NSManagedObjectID * objectID = [args objectAtIndex:0];
		NSNumber * indicator = [args objectAtIndex:1];
		SongVoteRecordedIndicator recorded = [indicator intValue];
		
	NSError *error = nil;
	NSManagedObject * managedObject = [managedObjectContext existingObjectWithID:objectID error:&error];
	if (managedObject != nil) {
		[managedObject setValue:[NSNumber numberWithInt:recorded] forKey:@"ratingSent"];

		if (![managedObjectContext save:&error]) {
			if(error != nil) { 
				NSLog(@"Error saving voteRecorded.");
			} 
		}
	}
}

- (void) voteCleanup {
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"voteCleanup must be done on the main thread.");
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	
	NSString * predString = [NSString stringWithFormat:@"rating > 0"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	[request setPredicate:predicate];
	
	NSArray * fetchResults = [managedObjectContext executeFetchRequest:request error:&error]; 
	
	//NSLog(@"Sorting through %d songs to cleanup votes", [fetchResults count]);
	
	for( NSManagedObject * song in fetchResults) {
		[song setValue:[NSNumber numberWithInt:0] forKey:@"rating"];
		[song setValue:[NSNumber numberWithInt:songVoteRecordedUnknown] forKey:@"ratingSent"];
	}
	
	if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
		if(error != nil) { 
			[appDelegate processError:error];
		}
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:[playerDelegate refreshDate] forKey:[PlayerEventNotifications keyForStatus:AudioStreamerLastVoteCleanupDate]];
	}
	
	[request release];

	[pool drain];
}

#pragma mark -
#pragma mark Song Cleanup and Background DB update Support

- (void) songCleanup {
	NSAssert(![[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"songCleanup cannot execute on the main thread.");
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// Delete one item at a time, the first one...
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	NSManagedObjectContext * moc = [[NSManagedObjectContext alloc] init];
	[moc setPersistentStoreCoordinator: appDelegate.persistentStoreCoordinator];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:moc]; 
	[request setEntity:entity];
	
	NSString * predString = [NSString stringWithFormat:@"(favorite == 0) AND (topSong == 0) AND (missed == 0)"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	[request setPredicate:predicate];
	
	NSArray * fetchResults = [moc executeFetchRequest:request error:&error]; 
	
	//NSLog(@"Sorting through %d songs to cleanup", [fetchResults count]);
	
	NSTimeInterval days_8 = WEEK_IN_SECONDS + DAY_IN_SECONDS;
	
	for( NSManagedObject * song in fetchResults) {
		NSArray * recentlyPlayed = [song valueForKey:@"recentlyPlayed"];
		NSDate * dateAdded = [song valueForKey:@"addedOnTimestamp"];
		if(dateAdded == nil) {
			dateAdded = [[NSDate date] addTimeInterval:-days_8];
		}
		
		NSTimeInterval secs = -[dateAdded timeIntervalSinceNow];
		//NSLog(@"Date Added %@, secs=%f, playCount=%d", dateAdded, secs, [recentlyPlayed count]);
		if(secs >= days_8){
			if ([recentlyPlayed count] == 0) {
				//NSLog(@"Removing old unused song: %@", [song valueForKey:@"name"]);
				[self performSelectorOnMainThread:@selector(deleteManagedObject:) withObject:[song objectID] waitUntilDone:YES];
			}
		}
	}
	
	[self performSelectorOnMainThread:@selector(commitBackgroundChanges:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:[PlayerEventNotifications keyForStatus:AudioStreamerLastCleanupDate]];
	
	[request release];
	[moc release];
	[pool drain];
}

- (void) cleanUpNowPlayingList {
	NSAssert(![[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"cleanupNowPlayingList cannot be done on the main thread.");

	if(	nowPlayingCount != NSNotFound ) {
		
		nowPlayingCount++;

		if((nowPlayingCount - NOW_PLAYING_MAX) < 1) {
			return;
		}
	}	
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSManagedObjectContext * moc = [[NSManagedObjectContext alloc] init];
	[moc setPersistentStoreCoordinator: appDelegate.persistentStoreCoordinator];
	
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentlyPlayed" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];

	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
	[sortDescriptor release];
	
	NSArray * fetchResults = [moc executeFetchRequest:request error:&error]; 
	
	nowPlayingCount = [fetchResults count];
	
	NSInteger playsToDelete = nowPlayingCount - NOW_PLAYING_MAX;

	if (playsToDelete > 0) {
		// delete old now playing songs
		
		//NSLog(@"Sorting through %d recently played songs to cleanup", playsToDelete);
		
		for( NSManagedObject * play in fetchResults) {
			playsToDelete--;
			// NSLog(@"Deleting id=%@",[play objectID]);
			[self performSelectorOnMainThread:@selector(deleteManagedObject:) withObject:[play objectID] waitUntilDone:NO];
			if(playsToDelete==0) {
				break;
			}
		}
		
		[self performSelectorOnMainThread:@selector(commitBackgroundChanges:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
	}
	
	[request release];
	[moc release];
	[pool drain];

}

-(void) deleteManagedObject: (NSManagedObjectID *) objectID {
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"deleteManagedObject can only be done on the main thread.");
	NSError *error = nil;
	NSManagedObject * managedObject = [managedObjectContext existingObjectWithID:objectID error:&error];
	if (managedObject != nil) {
		// NSLog(@"Deleting id=%@",[managedObject objectID]);
		[managedObjectContext deleteObject:managedObject];
	}
}

-(void) commitBackgroundChanges: (NSNumber *) commit {
	if (![managedObjectContext hasChanges])
		return;
	NSError *error = nil;
	if ([commit boolValue]) {
		if (![managedObjectContext save:&error]) {
			if(error != nil) { 
				[appDelegate processError:error];
			} 
		}
	} else {
		[managedObjectContext rollback];
	}
}

- (void) createMissedSongsBackground: (SongPickerView *) notify {
//	NSAssert(![[NSThread currentThread] isEqual:[NSThread mainThread]],
//			 @"createMissedSongs cannot execute on the main thread.");
//	
	[notify clearCache];
	
	[self deleteMissedSongs];
	
	NSArray * missedSongs = [playerDelegate localCreateMissedSongs];
	
	// Now try to match the missed songs against the now playing list
	Song * recentSong;
	for (Song * missedSong in missedSongs) {
		//		NSManagedObject *missed
		NSDate * missedTimestamp = [missedSong valueForKey:@"missedDate"]; // only one object in the set
		if((recentSong = [appDelegate findSong:[missedSong valueForKey:@"songID"]]) != nil) {
			NSSet * recentlyPlayed = [recentSong valueForKey:@"recentlyPlayed"];
			if ([recentlyPlayed count]) {
				for(NSManagedObject * recentPlay in recentlyPlayed) {
					NSDate * playTimestamp = [recentPlay valueForKey:@"timeStamp"];
					NSInteger offset = [playTimestamp timeIntervalSinceDate:missedTimestamp];
					//NSLog(@"offset=%d", offset);
					if (offset < MISSED_SONGS_OFFSET_GRACE_SECONDS) {
						//NSLog(@"Deleting...");
						// delete from the missed list because we heard at least part of it...
						[missedSong setValue:[NSNumber numberWithBool:NO] forKey:@"missed"];
					} else {
						// create missed song as a RecentSong
						RecentlyPlayed * play = [NSEntityDescription insertNewObjectForEntityForName:@"RecentlyPlayed" inManagedObjectContext:managedObjectContext];
						// copy the missed timestamp to the recents timestamp
						[play setValue:[missedSong valueForKey:@"missedDate"] forKey:@"timeStamp"];
						[play setValue:[NSNumber numberWithBool:YES] forKey:@"missed"];
						[missedSong addRecentlyPlayedObject:play];
					}
				}
			} else {
				// create missed song as a RecentSong
				RecentlyPlayed * play = [NSEntityDescription insertNewObjectForEntityForName:@"RecentlyPlayed" inManagedObjectContext:managedObjectContext];
				// copy the missed timestamp to the recents timestamp
				[play setValue:[missedSong valueForKey:@"missedDate"] forKey:@"timeStamp"];
				[play setValue:[NSNumber numberWithBool:YES] forKey:@"missed"];
				[missedSong addRecentlyPlayedObject:play];
			}
			
		}
	}
	
	[self performSelectorOnMainThread:@selector(commitBackgroundChanges:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
	
	//[notify performSelectorOnMainThread:@selector(loadData) withObject:nil waitUntilDone:NO];
	
}

- (void) deleteMissedSongs {

	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	
	NSString * predString = [NSString stringWithFormat:@"missed == 1"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	[request setPredicate:predicate];	
	
	NSArray * fetchResults = [managedObjectContext executeFetchRequest:request error:&error]; 
	
	for( NSManagedObject * song in fetchResults) {
		[song setValue:[NSNumber numberWithBool:NO] forKey:@"missed"];
	}
	
	[request release];
}

- (void) createTopSongsBackground: (SongPickerView *) notify {
//	NSAssert(![[NSThread currentThread] isEqual:[NSThread mainThread]],
//			 @"createTopSongs cannot execute on the main thread.");
	
	NSArray * oldTopSongs = [self getTopSongs];
	NSArray * newTopSongs = [playerDelegate localCreateTopSongs];
	
	if (newTopSongs == nil) {
		return; // no new top songs data, so do nothing
	}
	
	// remove old songs that are no longer top songs
	NSInteger idx;
	for( NSManagedObject * song in oldTopSongs) {
		idx = [newTopSongs indexOfObjectIdenticalTo:song];
		if (idx == NSNotFound) {
			[song setValue:NO forKey:@"topSong"];
		}
	}
	
	[self performSelectorOnMainThread:@selector(commitBackgroundChanges:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsAreFresh]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsLastFetchDate]];
	
	//[notify performSelectorOnMainThread:@selector(loadData) withObject:nil waitUntilDone:NO];
}


- (NSArray *) getTopSongs {

	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	
	NSString * predString = [NSString stringWithFormat:@"topSong == 1"];
	NSPredicate * predicate = [NSPredicate predicateWithFormat:predString];
	[request setPredicate:predicate];
	
	NSArray * results = [managedObjectContext executeFetchRequest:request error:&error]; 
	
	[request release];
	return results;
}

#pragma mark -
#pragma mark Progress Timer
//
// updateProgress:
//
// Invoked when the AudioStreamer
// reports that its playback progress has changed.
//
- (void)updateProgress:(NSTimer *)updatedTimer
{
	if (streamer.bitRate != 0.0)
	{
		
		if( progress != streamer.progress ) {
			self.timePlayed = [self formattedTime:progress];
			progress = streamer.progress;
		}

	}
	else
	{
		self.timePlayed = @"00:00:00";
		progress = 0.0;
	}
}
- (void) resetTime {
	progressUpdateTimer =
	[NSTimer
	 scheduledTimerWithTimeInterval:1.0
	 target:self
	 selector:@selector(updateProgress:)
	 userInfo:nil
	 repeats:YES];
	
	days=hours=minutes=seconds=0;
	progress = 0.0;
}

- (NSString *) formattedTime:(double) progress {
	if(++seconds > 59) {
		minutes++;
		seconds = 0;
	}
	
	if(minutes > 59){
		hours++;
		minutes = 0;
	}
	
	if(hours > 24 ) {
		days++;
		hours=0;
	}
	
	static NSNumberFormatter *numberFormatter = nil;
    if (numberFormatter == nil) {
        numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setPaddingCharacter:@"0"];
		[numberFormatter setFormatWidth:2];
		[numberFormatter setPaddingPosition:NSNumberFormatterPadBeforePrefix];
        [numberFormatter setNumberStyle:kCFNumberFormatterNoStyle];
        [numberFormatter setMaximumFractionDigits:0];
    }
	
	NSString *fmt = @"";
	
	if (days) {
		NSString *daysString = (days==1) ? @"day " : @"days ";
		fmt = [[[NSNumber numberWithInt:days] stringValue] stringByAppendingString:daysString];
	}
	
	fmt = [fmt stringByAppendingString:@"%@:%@:%@"];
	
	NSString *response = [NSString stringWithFormat:fmt, 
						  [numberFormatter stringFromNumber:[NSNumber numberWithInt:hours]], 
						  [numberFormatter stringFromNumber:[NSNumber numberWithInt:minutes]], 
						  [numberFormatter stringFromNumber:[NSNumber numberWithInt:seconds]]];
	
	return response;
	
}

#pragma mark -
#pragma mark PrefsViewControllerDelegate Methods

- (void) showInfoView:(BOOL)animated {
    PreferencesController *prefsController = [[PreferencesController alloc] init];
	prefsController.delegate = self;
	prefsController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:prefsController];
	[playerDelegate customizeNavigationController:navigationController];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:[PlayerEventNotifications keyForStatus:StartupRestoreShowingPreferences]];
    [self presentModalViewController:navigationController animated:animated];
    [navigationController release];
    [prefsController release];
}

- (IBAction) showInfo:(id)sender {
	[self showInfoView:YES];
}

- (void) restartStream 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[streamer stop:NO reason:AS_STOPPING_USER_RESTART];
	[pool drain];
}

- (void)prefsViewControllerDidFinish:(PreferencesController *)controller {

	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[PlayerEventNotifications keyForStatus:StartupRestoreShowingPreferences]];
	
	if(appDelegate.stationIndex != controller.selectedStationIndex) {
		
		[appDelegate setStationWithIndex:controller.selectedStationIndex];
		
		if(streamer.isPlaying || streamer.isWaiting) {
			[self performSelectorInBackground:@selector(restartStream) withObject:nil];
		}
		
	}
	
	[self dismissModalViewControllerAnimated:YES];
	
	changingOrientation = NO;

	self.view.hidden = NO;

}

- (void)prefsViewControllerDidCancel:(PreferencesController *)controller {
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[PlayerEventNotifications keyForStatus:StartupRestoreShowingPreferences]];
	[self dismissModalViewControllerAnimated:YES];
	changingOrientation = NO;
	self.view.hidden = NO;
}

#pragma mark -
#pragma mark AudioStreamer Control

//
// createStreamer
//
// Creates or recreates the AudioStreamer object.
//
- (void)createStreamer
{

	[self destroyStreamer];
	
	streamer = [[AudioStreamer alloc] initWithStation:appDelegate.streamOption];
	
	if(streamer == nil) {
		return;
	}
	
	streamer.errorHandlerDelegate = self;
	
	[self resetTime];
	
#if DEBUG_SCREEN
	[streamer addObserver:self forKeyPath:@"bufferCount" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
#endif
	[streamer addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	[streamer addObserver:self forKeyPath:@"track" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	[streamer addObserver:self forKeyPath:@"bitRateString" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	[streamer addObserver:self forKeyPath:@"dataFormat" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	
	[streamer performSelectorInBackground:@selector(start) withObject:nil];

}

//
// destroyStreamer
//
// Removes the streamer, the UI update timer and the change notification
//
- (void)destroyStreamer
{
	
	if (streamer)
	{
		[streamer stop];
		
#if DEBUG_SCREEN
		[streamer removeObserver:self forKeyPath:@"bufferCount"];
#endif
		[streamer removeObserver:self forKeyPath:@"state"];
		[streamer removeObserver:self forKeyPath:@"track"];
		[streamer removeObserver:self forKeyPath:@"bitRateString"];
		[streamer removeObserver:self forKeyPath:@"dataFormat"];
		
		[progressUpdateTimer invalidate];
		progressUpdateTimer = nil;
		
		[streamer release];
		streamer = nil;
		
		self.bitRate = @"";
		
	}
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// retry
		[self performSelector:@selector(start) withObject:nil];
	}
}


- (void) startNetworkActivity {
	if(pageControl.currentPage == 0 ) {
		[self activityAnimationStart:YES];
		//NSLog(@"Started");
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopNetworkActivity) object:nil];
	[self performSelector:@selector(stopNetworkActivity) withObject:nil afterDelay:2.5];

}
- (void) stopNetworkActivity {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark AVAudioSession Management and Delegate Methods

//
// beginInterruption: (Audio Session)
//
// Implementation for beginInterruption method for AVAudioSessionDelegate protocol
//
// Parameters:
-(void) beginInterruption {
	if(userAction == ASC_STARTPLAY) {
		[streamer pause];
		NSLog(@"streamer paused");
//		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayerInterrupted]];
	}
}
//
// endInterruption: (Audio Session)
//
// Implementation for endInterruption method for AVAudioSessionDelegate protocol
//
// Parameters:
-(void) endInterruption {
	// User did not answer the phone
	
//	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayerInterrupted]];
	BOOL wasPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];

	if(wasPlaying) {
		NSError *error = nil;
		[audioSession setActive:YES error: &error];
		if (error != nil) {
			NSLog(@"streamer error");
			[appDelegate processError:error];
		} else {
			[streamer pause];
			NSLog(@"streamer restart pause");
		}
	}
}

// Audio session callback function for responding to audio route changes. If playing 
//		back application audio when the headset is unplugged, this callback pauses 
//		playback and displays an alert that allows the user to resume or stop playback.
//
//		The system takes care of iPod audio pausing during route changes--this callback  
//		is not involved with pausing playback of iPod audio.
- (void) handleAudioRouteChange: (AudioSessionPropertyID) inPropertyID
			inPropertyValueSize: (UInt32) inPropertyValueSize 
				inPropertyValue: (const void *) inPropertyValue {
	
	// ensure that this callback was invoked for a route change
	if (inPropertyID != kAudioSessionProperty_AudioRouteChange) {
		return;
	}
	
	
	// if application sound is not playing, there's nothing to do, so return.
	if ([streamer isIdle]) {
		// NSLog (@"Audio route change while application audio is stopped.");
		return;
		
	} else {
		
		// Determines the reason for the route change, to ensure that it is not
		//		because of a category change.
		
		NSDictionary *routeChangeDictionary = (NSDictionary *) inPropertyValue;
		
		NSString *key = [NSString stringWithCString:kAudioSession_AudioRouteChangeKey_Reason encoding:NSASCIIStringEncoding];
		NSNumber *routeChangeReason = [routeChangeDictionary objectForKey:key];
		
		// "Old device unavailable" indicates that a headset was unplugged, or that the
		//	device was removed from a dock connector that supports audio output. This is
		//	the recommended test for when to pause audio.
		if ([routeChangeReason intValue] == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
			
			//NSLog (@"Output device removed, so application audio was stopped.");
			
			[streamer stop:YES reason:AS_STOPPING_AUDIO_ROUTE_CHANGE];
			
		} else {
			
			// NSLog (@"A route change occurred that does not require stopping of application audio.");
		}
	}
}

/*
- (void)currentHardwareOutputNumberOfChannelsChanged:(NSInteger)numberOfChannels {
	NSLog(@"Output channels was %d is now: %d", currentAudioSessionOutputChannels, numberOfChannels);
	currentAudioSessionOutputChannels = numberOfChannels;
}
- (void)categoryChanged:(NSString*)category {
	NSLog(@"AudioSession category changed");
 }
- (void)currentHardwareInputNumberOfChannelsChanged:(NSInteger)numberOfChannels {
	NSLog(@"AudioSession input channels changed: %d", numberOfChannels);
 }
- (void)inputIsAvailableChanged:(BOOL)isInputAvailable {
	NSLog(@"AudioSession input is available: %d", isInputAvailable);
 }
*/
- (void)playerWillEnterForeground{
	switch (streamer.state) {
		case AS_PLAYING:
			break;
		case AS_PAUSED:
			[streamer pause];
			break;
		default: {
			BOOL wasPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
			if (wasPlaying) {
				if([streamer isWaiting]){
					// do nothing
				} else {
					if (self.userAction == ASC_STARTPLAY) {
						NSLog(@"Restart playing");
						[self restart];
					}
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Connectivity Helpers

- (BOOL) isReachable {

	self.reachable = !([currentReach currentReachabilityStatus] == NotReachable);

	if (!reachable) {
		
		UIAlertView *alert =
		[[[UIAlertView alloc]
		  initWithTitle:NSLocalizedStringFromTable(@"Error", @"Errors", nil)
		  message:NSLocalizedStringFromTable(@"InternetDown", @"Errors", nil)
		  delegate:self
		  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Buttons", nil)
		  otherButtonTitles: nil]
		 autorelease];
		
		[alert 
		 performSelector:@selector(show)
		 onThread:[NSThread mainThread]
		 withObject:nil
		 waitUntilDone:NO];
		
		return NO;
	}
	return YES;
}
/*
- (void) setReachabilityStatus {	
	
	CATransition *transition = [CATransition animation];
	
	transition.duration = 1.00;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
	
	[reachabilitySource.layer addAnimation:transition forKey:nil];
	
	reachabilitySource.hidden = YES;

	NetworkStatus stat = [currentReach currentReachabilityStatus];
	switch (stat) {
		case ReachableViaWiFi:
			reachabilitySource.text = @"WiFi";
			break;
		case ReachableViaWWAN:
			reachabilitySource.text = @"WWAN";
			break;
		case NotReachable:
		default:
			reachabilitySource.text = @"!";
	}

	// NSLog(@"Reachbility is now %@", reachabilitySource.text);
	reachabilitySource.hidden = NO;
}
*/

#pragma mark -
#pragma mark Battery State Management

- (void)batteryStateDidChange:(NSNotification *)notification
{

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString * autoLockKey = [PlayerEventNotifications keyForStatus:AudioStreamerAutoLock];

	id existsDefault = [defaults objectForKey:autoLockKey];
	BOOL autoLock = YES;
	if(existsDefault == nil ) {
		[defaults setBool:autoLock forKey:autoLockKey];
	} else {
		autoLock = [defaults boolForKey:autoLockKey];
	}
	
	if (!autoLock) {
		switch ([[UIDevice currentDevice] batteryState]) {
			case UIDeviceBatteryStateUnknown:
			case UIDeviceBatteryStateUnplugged:
				// Unplugged
				//NSLog(@"Autolock is enabled because the device is not externally powered.");
				[UIApplication sharedApplication].idleTimerDisabled = NO;
				//autoLockDisabled.text = @"NO - 1";
				break;
			case UIDeviceBatteryStateCharging:
			case UIDeviceBatteryStateFull:
				// Powered
				//NSLog(@"Autolock is disabled because the device is externally powered.");
				[UIApplication sharedApplication].idleTimerDisabled = YES;
				//autoLockDisabled.text = @"YES";
				break;
			default:
				//NSLog(@"Autolock is disabled Default");
				break;
		}
	} else {
		// autoLockDisabled.text = @"NO - 0";
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		//NSLog(@"Autolock is ON");
	}	
	//NSLog(@"idleTimerDisabled=%d", [UIApplication sharedApplication].idleTimerDisabled);
}


#pragma mark -
#pragma mark Installation-specific methods

-(NSManagedObject *)createStation:(NSManagedObject *)newStation {
	return [playerDelegate createStation: newStation];
}
-(NSArray *)createStreamOptions {
	return [playerDelegate createStreamOptions];
}

- (NSString *) aboutURL {
	return [playerDelegate aboutURL];
}
- (NSString *) supportURL {
	return [playerDelegate supportURL];
}

- (NSDate *) topSongsDate {
	return [playerDelegate topSongsDate];
}
- (BOOL) topSongsAreRefreshed:(NSDate *) lastRefreshedOn {
	return [playerDelegate topSongsAreRefreshed:lastRefreshedOn];
}

- (NowPlayingViewController *) nowPlayingController {
	
    if (nowPlayingController != nil) {
        return nowPlayingController;
    }
	
	nowPlayingController = [[NowPlayingViewController alloc] initWithNibName:[playerDelegate nowPlayingPortraitNib] bundle:nil];

	return nowPlayingController;
}

- (UIImageView *) imageViewNamed: (NSString *) imgName {
	UIImage * img = [UIImage imageNamed:imgName];
    return [[[UIImageView alloc] initWithImage:img] autorelease];
}
- (UIImageView *) imageViewPlay {
	
    if (imageViewPlay != nil) {
        return imageViewPlay;
    }
	return self.imageViewPlay = [self imageViewNamed:@"Play.png"];
}
- (UIImageView *) imageViewPause {
	
    if (imageViewPause != nil) {
        return imageViewPause;
    }
	return self.imageViewPause = [self imageViewNamed:@"Pause.png"];
}
- (UIImageView *) imageViewStop {
	
    if (imageViewStop != nil) {
        return imageViewStop;
    }
	return self.imageViewStop = [self imageViewNamed:@"Stop.png"];
}

- (SplashController *) splashController {
    if (splashController != nil) {
        return splashController;
    }
	return self.splashController = [[SplashController alloc] init];
}
-(void) trackChangedToNewSong {
}

- (UIColor *) ratingColor:(NSNumber *) songRating {
	return [UIColor blackColor];
}

@end

