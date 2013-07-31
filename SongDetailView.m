//
//  SongDetailView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/16/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SongDetailView.h"
#import "MusicPlayerController.h"
#import "Song.h"
#import "PlayerEventNotifications.h"

@implementation SongDetailView

@synthesize songNameLabel, artistLabel, mixLabel, ratingLabel, topRatedLabel, artistMixLabel;
@synthesize songID, addedOn, lastServerRefresh, topRated;
@synthesize songName;
@synthesize artist;
@synthesize mix;
@synthesize wallpaper;

@synthesize containerView;

@synthesize ratingController, ratingControllerContainer;

- (id) initWithSong: (NSManagedObject *) song {
	self.appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
	id <MusicPlayerDelegate> playerDelegate = appDelegate.rootViewController.playerDelegate;

	if(self = [super initWithNibName:[playerDelegate songDetailNib] bundle:nil]) {
		managedObject = song;
	}
	return self;
}

- (void) viewDidLoad {
	
	self.entityName = @"Song";
    [ratingController setManagedObject:managedObject];
	if([managedObject.entity.name isEqual:@"RecentlyPlayed"] || [managedObject.entity.name isEqual:@"Missed"]){
		managedObject = [managedObject valueForKey:@"song"];
	}

	self.fetchPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"songID == %@", [managedObject valueForKey:@"songID"]]];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"songID" ascending:YES];
	NSArray * sortDescs = [NSArray arrayWithObjects:sortDescriptor, nil];
	[sortDescriptor release];
	
	self.sortDescriptors = sortDescs;
	
	self.detailDelegate = self;
	
	self.title = NSLocalizedStringFromTable(@"Song", @"Tables", nil);
	
	// localize the display labels
	self.songNameLabel.text = NSLocalizedStringFromTable(@"Song", @"Tables", nil);
	self.artistMixLabel.text = NSLocalizedStringFromTable(@"ArtistMix", @"Tables", nil);
	self.ratingLabel.text = NSLocalizedStringFromTable(@"Rating", @"Tables", nil);
	self.topRatedLabel.text = NSLocalizedStringFromTable(@"TopRated", @"Tables", nil);
	
	ratingController.parentController = self;
	[ratingControllerContainer addSubview:ratingController.view];
	CGRect frame = ratingController.view.frame;
	frame.origin.x = frame.origin.y = 0;
	ratingController.view.frame = frame;
	
	ratingController.playerDelegate = appDelegate.rootViewController.playerDelegate;

	[super viewDidLoad];

	[[NSUserDefaults standardUserDefaults] setValue:[managedObject valueForKey:@"songID"] forKey:[PlayerEventNotifications keyForStatus:StartupRestoreDetailSongID]];

	[appDelegate.rootViewController.currentReach addObserver:self forKeyPath:@"reachable" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

	Reachability * internetReachable = [Reachability reachabilityForInternetConnection];
	BOOL reachable = !([internetReachable currentReachabilityStatus] == NotReachable);
	ratingController.view.userInteractionEnabled = reachable;
}

- (void)viewDidUnload {

	self.songID = nil;
	self.addedOn = nil;
	self.lastServerRefresh = nil;
	self.topRated = nil;
	
	self.songName = nil;
	self.artist = nil;
	self.mix = nil;

	self.wallpaper = nil;

	self.ratingController = nil;
	self.ratingControllerContainer = nil;
	
	self.containerView = nil;

	[appDelegate.rootViewController.currentReach removeObserver:self forKeyPath:@"reachable"];

    [super viewDidUnload];
}

- (void)dealloc {
	
	[songID release];
	[addedOn release];
	[lastServerRefresh release];
	[topRated release];
	
	[songName release];
	[mix release];
	[artist release];
	
	[ratingControllerContainer release];
	[ratingController release];
	[containerView release];
	
	[wallpaper release];
	
    [super dealloc];
}

- (void) restoreState {
}

- (void)saved {
}

- (void) copyDataToManagedObject {
	@synchronized(self) {
		[managedObject setValue:ratingController.rating forKey:@"rating"];
	}
}

- (void) enableEdits:(BOOL) enable {
}

- (void) ratingChanged {
	@synchronized(self) {
		[self save];

		Song * song = (Song *) managedObject;
		[song saveRating:ratingController.rating];
	
		NSArray * voteargs = [NSArray arrayWithObjects:song.songID, song.rating, [song objectID], nil ];
		
		[appDelegate.rootViewController  performSelectorInBackground:@selector(vote:) withObject:voteargs];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([keyPath isEqual:@"reachable"]) {
		BOOL reach = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		ratingController.view.userInteractionEnabled = reach;
	}
}

@end
