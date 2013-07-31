//
//  MusicOneViewController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/04/2010.
//  Copyright Total Managed Fitness 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MusicPlayerAppDelegate.h"
#import "AudioStreamer.h"
#import "PreferencesController.h"
#import "RecentlyPlayed.h"
#import "PlayerEventNotifications.h"

@class SongsTabBarController;
@class NowPlayingViewController;
@class BandwidthController;
@class SplashController;

#define ASVC_MAXERRORS 30
#define NOW_PLAYING_MAX 40
#define PAUSEPLAY_FADEOUT_SECONDS 5.0
//#define INTERNET_CONNECTION_LOST_RETRY_SECONDS 20.0
#define OTHER_ERROR_RETRY_SECONDS 10.0
#define FULLSONGNAME_QUERY_DELAY_MAX 8

// 6 minutes...
#define MISSED_SONGS_OFFSET_GRACE_SECONDS 360 

typedef enum
	{
		ASC_STARTPLAY = 0,
		ASC_STOPPLAY
	} AudioStreamerControllerUserAction;

void audioRouteChangeListenerCallback (
									   void                      *inUserData,
									   AudioSessionPropertyID    inPropertyID,
									   UInt32                    inPropertyValueSize,
									   const void                *inPropertyValue
									   );

@class AudioStreamer;
@class SongPickerView;

@protocol MusicPlayerDelegate;

@interface MusicPlayerController : UIViewController <PrefsControllerDelegate, AVAudioSessionDelegate, 
		AudioStreamerErrorHandlerDelegate, UIActionSheetDelegate, 
		UINavigationControllerDelegate,
		UIScrollViewDelegate> 
{

	UIScrollView *scrollView;
	UIPageControl *pageControl;
	BOOL scrollUsed;
	NSMutableArray *pageViewControllers;
	
	BOOL changingOrientation;
			
	UIBarButtonSystemItem currentSystemItem;
	UIButton *playPauseButton;
	UIButton *infoButton;
	UIActivityIndicatorView *activityView;
	BandwidthController * bandwidthController;

	UIImageView *imageViewPause, *imageViewPlay, *imageViewStop;
	
	SplashController * splashController;
	NowPlayingViewController * nowPlayingController;
	SongsTabBarController * songsViewController;
			
	UIView *previousView;
	UIView *containerView, *containerView1;
	
	NSTimer *progressUpdateTimer;
	NSUInteger timeValue;
	double progress;
	NSUInteger days, hours, minutes, seconds;
			
	BOOL streaming;
	AudioStreamer *streamer;
	AVAudioSession *audioSession;
	NSInteger currentAudioSessionOutputChannels;
	AudioStreamerControllerUserAction userAction;
	
	NSString *songID, *track, *bitRate, *timePlayed, *dataFormatString;
	UInt32 dataFormat;
	NSFetchedResultsController *fetchedResultsController;
	NSManagedObjectContext *managedObjectContext;
	NSManagedObject * currentRecentlyPlayed;
	Song * nowPlayingSong;
			
	NSUInteger errorCount;
	
	MusicPlayerAppDelegate *appDelegate;
	
	NSDateComponents *topSongsRefreshDateTemplate;
	
	Reachability * currentReach;
	NetworkStatus netStatus;
	BOOL reachable;
	//UILabel * reachabilitySource;
	
#if DEBUG_SCREEN
	UILabel * playerStatus, * buffersUsed; //, *autoLockDisabled;
										   //UITextView * consoleView;
#endif
	
	id <MusicPlayerDelegate> playerDelegate;

	NSInteger nowPlayingCount;
	NSInteger currentPageNumber;
			
	UIColor * onColor, *offColor;

	BOOL showDefaultScreen;
}

#if DEBUG_SCREEN
@property (nonatomic, retain) UILabel * playerStatus, * buffersUsed; //, *autoLockDisabled;
																	 //@property (nonatomic, retain) UITextView *consoleView;
#endif

@property (nonatomic, assign) SongsTabBarController * songsViewController;

@property (nonatomic, retain) UIColor * onColor, * offColor;
@property (nonatomic, retain) Reachability *currentReach;
//@property (nonatomic, retain) UILabel *reachabilitySource;

@property (nonatomic, assign) NetworkStatus netStatus;
@property (nonatomic, assign) BOOL reachable;

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *containerView, *containerView1;
@property (nonatomic, retain) UIPageControl *pageControl;
@property (nonatomic, retain) NSMutableArray *pageViewControllers;

@property (nonatomic, retain) NSDateComponents *topSongsRefreshDateTemplate;
@property (nonatomic, assign) AudioStreamerControllerUserAction userAction;

@property (nonatomic, retain) NSString *songID, *track, *bitRate, *timePlayed, *dataFormatString;
@property (nonatomic, assign) UInt32 dataFormat;

@property (nonatomic, retain) UIActivityIndicatorView * activityView;
@property (nonatomic, retain) IBOutlet UIButton *playPauseButton;
@property (nonatomic, assign) UIButton *infoButton;

@property (nonatomic, retain) BandwidthController * bandwidthController;

@property (nonatomic, retain) SplashController * splashController;

@property (nonatomic, retain) UIImageView *imageViewStop;
@property (nonatomic, retain) UIImageView *imageViewPlay;
@property (nonatomic, retain) UIImageView *imageViewPause;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) Song * nowPlayingSong;
@property (nonatomic, retain) MusicPlayerAppDelegate * appDelegate;

@property (nonatomic, assign) id <MusicPlayerDelegate> playerDelegate;

@property (nonatomic, assign) NowPlayingViewController *nowPlayingController;

- (void) restore;

- (void) start;
- (void) stop;
- (void) restart;

- (IBAction)changePage:(id)sender;
- (void)loadScrollViewWithPage:(int)page;
- (void) updateNavigation: (BOOL) animated;

- (IBAction)buttonPressed:(id)sender;
- (void)updateProgress:(NSTimer *)aNotification;
- (IBAction) showInfo:(id)sender;
- (void) showInfoView:(BOOL) animated;

- (void) updateToolbar:(BOOL) animated;
- (void)showSplash;
- (void) resetTime;
- (NSString *) formattedTime:(double) progress;
- (NSManagedObject *) addRecentlyPlayedSong:(NSManagedObject *) song;
- (Song * ) getNowPlayingSong: (NSString *) newSongID trackName: (NSString *) songName ;
- (void) announceToNowPlayingControllers;

- (void) adjustContainerViews:(UIInterfaceOrientation)toInterfaceOrientation;

- (void) songCleanup;
- (void) voteCleanup;

-(void) pushViewController: (UIViewController *) controller animated:(BOOL) animated;

-(void) deleteMissedSongs;
-(NSArray *) getTopSongs;
-(void) voteRecorded:(NSArray *) args;

- (NSString *) aboutURL;
- (NSString *) supportURL;

-(NSManagedObject *)createStation:(NSManagedObject *)newStation;
-(NSArray *)createStreamOptions;

- (void) createMissedSongsBackground: (SongPickerView *) notify;
- (void) createTopSongsBackground: (SongPickerView *) notify;

- (NSDate *) topSongsDate;
- (BOOL) topSongsAreRefreshed:(NSDate *) lastRefreshedOn;
- (Song *) songFromDictionary:(NSDictionary *) songDataDict processMissed:(BOOL) processMissed;
- (void) hideBandwidth:(BOOL) hidden;

- (UIColor *) ratingColor:(NSNumber *) songRating;

- (void) handleAudioRouteChange: (AudioSessionPropertyID) inPropertyID
			inPropertyValueSize: (UInt32) inPropertyValueSize
				inPropertyValue:(const void *) inPropertyValue ;
- (UIImageView *) imageViewNamed: (NSString *) imgName;
-(void) trackChangedToNewSong;
- (void) activityAnimationStart:(BOOL) start;

- (void)playerWillEnterForeground;

@end

@protocol MusicPlayerDelegate
-(Song *)createSong:(NSString *)trackName;
- (NSDictionary *) songDictionaryFromString:(NSString *) encodedSongData processMissed:(BOOL) processMissed;

-(NSManagedObject *)createStation:(NSManagedObject *)newStation;
-(NSArray *)createStreamOptions;

- (NSString *) missedSongsURL;
- (NSArray *) localCreateMissedSongs;

- (NSString *) topSongsURL;
- (NSArray *) localCreateTopSongs;
- (NSDate *) topSongsDate;
- (BOOL) topSongsAreRefreshed:(NSDate *) lastRefreshedOn;

- (void) vote:( NSArray *) args;
- (NSDate *) voteClearDate;

- (NSString *) aboutURL;
- (NSString *) supportURL;
- (NSString *) songDataURL:(NSString *) songID;

- (NSDate *) refreshDate;

- (NSString *) nowPlayingPortraitNib;
- (NSString *) nowPlayingLandscapeNib;
- (NSString *) songDetailNib;
- (NSString *) backButtonImageName;
- (void) customizeStartupView;
- (void) updateCustomNavigation:(BOOL) animated;
- (void) showSplash;
- (void) customizeNavigationController:(UINavigationController *) navigationController;
- (void)showNowPlayingSong;
- (void)trackChanged;



@end

