//
//  NowPlayingViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/11/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "NowPlayingViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Song.h"

@implementation NowPlayingViewController

@synthesize songName;
@synthesize artist;
@synthesize mix;

@synthesize songID, nowPlayingLabel, rateItLabel;
@synthesize trackName;
@synthesize nowPlayingSong;
@synthesize appDelegate;

@synthesize containerView;
@synthesize ratingController, ratingControllerContainer;

@synthesize fetchedResultsController, songPredicate;

@synthesize playerViewController;
@synthesize timePlayed;

@synthesize containerContentView, bottomView;

- (void)viewDidLoad {
	self.appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate.rootViewController.currentReach addObserver:self forKeyPath:@"reachable" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

	self.playerViewController = appDelegate.rootViewController;

	wallpaper.image = [self wallPaperImage:[self interfaceOrientation]];

	[self setupObservers];
	
	ratingController.parentController = self;
	ratingController.playerDelegate = appDelegate.rootViewController.playerDelegate;

	[ratingControllerContainer addSubview:ratingController.view];
	CGRect frame = ratingController.view.frame;
	frame.origin.x = frame.origin.y = 0;
	ratingController.view.frame = frame;
	
	nowPlayingLabel.text = NSLocalizedStringFromTable(@"NowPlaying", @"App", nil);
	rateItLabel.text = NSLocalizedStringFromTable(@"RateIt", @"App", nil);
	
	NSString * fontSizeString = NSLocalizedStringFromTable(@"rateItFontSize", @"App", nil);
	CGFloat fSize = [fontSizeString floatValue];
	if (fSize > 0.0) {
		rateItLabel.font = [UIFont systemFontOfSize:fSize];
	}
	
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	[self cancelObservers];
	
	self.trackName = nil;
	self.songID = nil;
	self.rateItLabel = nil;
	self.nowPlayingLabel = nil;
	self.songPredicate = nil;
	self.fetchedResultsController = nil;
	self.containerView = nil;
	self.ratingController = nil;
	self.ratingControllerContainer = nil;
	self.containerContentView = nil;
	self.bottomView = nil;
	self.artist = nil;
	self.mix = nil;
	self.songName = nil;
	
	self.timePlayed = nil;
	
	self.wallpaper = nil;
	
	[appDelegate.rootViewController.currentReach removeObserver:self forKeyPath:@"reachable"];

}

- (void)dealloc {
	
	//	[self cancelObservers];

	[containerContentView release];
	[trackName release];
	[songID release];
	[rateItLabel release];
	[nowPlayingLabel release];
	[fetchedResultsController release];
	[songPredicate release];

	[containerView release];
	[bottomView release];
	
	[ratingControllerContainer release];
	[ratingController release];
	
	[songName release];
	[mix release];
	[artist release];
	
	
	[timePlayed release];
	
	[wallpaper release];
	
	[super dealloc];
}

- (UIImage *) wallPaperImage:(UIInterfaceOrientation)forInterfaceOrientation {
	return (UIInterfaceOrientationIsPortrait(forInterfaceOrientation)) ? 
	[UIImage imageNamed:@"NowPlayingPortrait.png"] :
	[UIImage imageNamed:@"NowPlayingLandscape.png"];
}
#pragma mark -
#pragma mark UIInterfaceOrientation Management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark CoreData Binding Management
- (void) songToUI {
	
	Song * song = (Song *) nowPlayingSong;
	
	ratingController.managedObject = song;

	ratingController.serverState = [[song valueForKey:@"ratingSent"] intValue];
	ratingController.rating = [song valueForKey:@"rating"];
	
	[ratingController performSelector:@selector(updateRatingView) withObject:nil afterDelay:1.0];

}

-(void) setSong:(NSManagedObject *) song {

	self.nowPlayingSong = song;
	
	if(self.view == nil)
		return;

	[self songToUI];
}

-(void) newSongPlaying: (NSManagedObject *) song {
	
	// only parse the predicate once
	if(songPredicate == nil) {
		self.songPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"songID == $SONG_ID"]];
	}

	if (nowPlayingSong != nil) {
		// check to see if rating needs to be saved
		if ([[nowPlayingSong valueForKey:@"ratingSent"] intValue] == songVoteRecordedPending) {
			// vote not yet recorded, so send it...
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(ratingChanged) object:nil];
			[self performSelector:@selector(ratingChanged)];
		}
	}
	
	NSNumber *nSongID = [song valueForKey:@"songID"];
	if (nSongID == nil) {
		return;
	}
	NSDictionary *variables = [NSDictionary dictionaryWithObject:nSongID forKey:@"SONG_ID"]; 
	NSPredicate *localPredicate = [songPredicate predicateWithSubstitutionVariables:variables];

	if(self.view == nil)
		return;
	
	NSFetchedResultsController * frc = self.fetchedResultsController;
	
	[frc.fetchRequest setPredicate:localPredicate];
	
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		[appDelegate processError:error];
		return;
	} else {
		NSInteger count = [fetchedResultsController.fetchedObjects count];
		if (count) {
			self.nowPlayingSong = [fetchedResultsController.fetchedObjects objectAtIndex:0];
		}
	}
	
	[self showNowPlayingSong];

}

- (void)showNowPlayingSong {
	MusicPlayerController * player = (MusicPlayerController *) ratingController.playerDelegate;
	[player performSelectorOnMainThread:@selector(showNowPlayingSong) withObject:nil waitUntilDone:NO];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	MusicPlayerController * player = (MusicPlayerController *) ratingController.playerDelegate;
	[player performSelectorOnMainThread:@selector(trackChangedToNewSong) withObject:nil waitUntilDone:NO];
}

- (void) ratingChanged {

	@synchronized(self) {
		Song * song = (Song *) nowPlayingSong;

		[song saveRating:ratingController.rating];
		
		NSArray * voteargs = [NSArray arrayWithObjects:song.songID, song.rating, [song objectID], nil ];

		[appDelegate.rootViewController  performSelectorInBackground:@selector(vote:) withObject:voteargs];
	}
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    /*
	 Set up the fetched results controller.
	 */

	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:appDelegate.managedObjectContext];
	
	[fetchRequest setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"songID" ascending:YES];
	NSArray * sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
										managedObjectContext:appDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;
	
	[aFetchedResultsController release];
	[fetchRequest release];
	
	return fetchedResultsController;
}    


#pragma mark -
#pragma mark NSFetchedResultsController Delegate Methods

/*
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	//NSLog(@"controllerWillChangeContent");
	//[self.tableView beginUpdates];
}
*/
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// this gets called if the song got updated elsewhere...so update the UI with the new data, too.
	MusicPlayerController * player = (MusicPlayerController *) ratingController.playerDelegate;
	[player performSelectorOnMainThread:@selector(trackChanged) withObject:nil waitUntilDone:NO];
}
/*
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	//UITableView *tableView = self.tableView;
	
	switch(type) {
		case NSFetchedResultsChangeDelete:
			//NSLog(@"NSFetchedResultsChangeDelete");
			break;
		case NSFetchedResultsChangeUpdate:
			//NSLog(@"NSFetchedResultsChangeUpdate");
			break;
	}
}
*/

- (void) setupObservers {
	[playerViewController addObserver:self forKeyPath:@"timePlayed" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void) cancelObservers {
	[playerViewController removeObserver:self forKeyPath:@"timePlayed"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([keyPath isEqual:@"timePlayed"]) {
		
		[self.timePlayed performSelectorOnMainThread:@selector(setText:) withObject:[change objectForKey:NSKeyValueChangeNewKey] waitUntilDone:NO];
		
	} else if ([keyPath isEqual:@"reachable"]) {
		BOOL reach = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		ratingController.view.userInteractionEnabled = reach;
	}
}


@end
