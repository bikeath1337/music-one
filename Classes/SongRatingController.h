//
//  SongRatngController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/01/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerEventNotifications.h"
#import "MusicPlayerController.h"


@interface SongRatingController : UIViewController {

	NSNumber * rating;
	NSArray * ratingObjects;
	
	CGPoint startTouchPosition;
	
	UIViewController * parentController;
	
	SongVoteRecordedIndicator serverState;
	
	NSManagedObject *managedObject;
	
	id <MusicPlayerDelegate> playerDelegate;
}

@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSArray * ratingObjects;
@property (nonatomic, retain) NSManagedObject * managedObject;
@property (nonatomic, retain) UIViewController * parentController;
@property (nonatomic, assign) SongVoteRecordedIndicator serverState;

@property (nonatomic, assign) id <MusicPlayerDelegate> playerDelegate;

- (void) ratingChanged: (NSNumber *) newRating;
- (IBAction) ratingTouched:(id) sender;
- (void) updateRatingView;

@end
