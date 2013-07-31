//
//  NowPlayingViewController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/11/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicPlayerController.h"
#import "MusicPlayerAppDelegate.h"
#import "SongRatingController.h"
#import "SplashController.h"

@interface NowPlayingViewController : SplashController <NSFetchedResultsControllerDelegate>{
	UILabel * songID, *nowPlayingLabel, *rateItLabel;
	UITextView * trackName;

	NSManagedObject * nowPlayingSong;
	
	MusicPlayerAppDelegate *appDelegate;
	
	NSPredicate * songPredicate;
	
	NSFetchedResultsController *fetchedResultsController;
	
	UIView * containerView;
	UIView *ratingControllerContainer;
	SongRatingController * ratingController;

	UILabel * songName;
	UILabel * artist;
	UILabel * mix;
	
	UILabel * timePlayed;
	
	MusicPlayerController *playerViewController;
	
	UIView * containerContentView;
	UIView * bottomView;

}

@property (nonatomic, retain) IBOutlet UIView * containerContentView, *bottomView;
@property (nonatomic, assign) MusicPlayerController * playerViewController;

@property (nonatomic, retain) IBOutlet UILabel * timePlayed;

@property (nonatomic, retain) IBOutlet UILabel * songName;
@property (nonatomic, retain) IBOutlet UILabel * artist;
@property (nonatomic, retain) IBOutlet UILabel * mix;

@property (nonatomic, retain) IBOutlet SongRatingController * ratingController;
@property (nonatomic, retain) IBOutlet UIView * ratingControllerContainer;

@property (nonatomic, retain) IBOutlet UIView *containerView;

@property (nonatomic, retain) IBOutlet UILabel * songID, *nowPlayingLabel, *rateItLabel;
@property (nonatomic, retain) IBOutlet UITextView * trackName;
@property (nonatomic, retain) NSManagedObject * nowPlayingSong;
@property (nonatomic, assign) MusicPlayerAppDelegate * appDelegate;

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSPredicate * songPredicate;

-(void) setSong:(NSManagedObject *) song;
-(void) newSongPlaying: (NSManagedObject *) song;

- (void)showNowPlayingSong;

//-(void)trackChanged;
- (void) songToUI;

- (void) setupObservers;
- (void) cancelObservers;

@end
