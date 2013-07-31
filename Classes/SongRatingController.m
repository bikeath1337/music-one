//
//  SongRatngController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/01/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SongRatingController.h"

#define RATING_SAVE_DELAY  3.0

@implementation SongRatingController

@synthesize playerDelegate;

@synthesize rating, ratingObjects, parentController, serverState, managedObject;

- (void) viewDidLoad {
	UIView *vw = self.view;
	self.ratingObjects = [NSArray arrayWithObjects:
					 [vw viewWithTag:1],
					 [vw viewWithTag:2],
					 [vw viewWithTag:3],
					 [vw viewWithTag:4],
					 [vw viewWithTag:5],
					 nil ];
	
	[self addObserver:self forKeyPath:@"rating" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

}

- (void) ratingChanged: (NSNumber *) newRating {
	NSInteger newRate = [rating integerValue];
	for (UIButton * ratingObject in ratingObjects) {
		if (serverState == songVoteRecordedNo) {
			ratingObject.highlighted = (ratingObject.tag > newRate) ? NO : YES;
			ratingObject.selected = NO;
		} else {
			ratingObject.selected = (ratingObject.tag > newRate) ? NO : YES;
			ratingObject.highlighted = NO;
		}

	}

}

- (IBAction) ratingTouched:(id) sender {
	UIButton * ratingObject = (UIButton *) sender;
	
	serverState = songVoteRecordedUnknown;
	NSInteger currentRating = [rating integerValue];
	if(currentRating == 1 && ratingObject.tag == 1) {
		// special case = toggle it off if it was on
		ratingObject.selected = NO;
		self.rating = [NSNumber numberWithInt:0];
	} else {
		self.rating = [NSNumber numberWithInt:ratingObject.tag];
	}
	
	[self performSelectorOnMainThread:@selector(ratingChanged) withObject:nil waitUntilDone:NO];

}

- (void) ratingChanged {
	[managedObject setValue:[NSNumber numberWithBool:([self.rating intValue] > 0) ? YES: NO] forKey:@"favorite"];
	[managedObject setValue:self.rating forKey:@"rating"];
	[managedObject setValue:[NSNumber numberWithInt:songVoteRecordedPending] forKey:@"ratingSent"];
	
//	NSLog(@"rating set on object = %d, %@, %@", [self.rating intValue], [managedObject objectID], managedObject);
	
	[NSObject cancelPreviousPerformRequestsWithTarget:parentController selector:@selector(ratingChanged) object:nil];
	[parentController performSelector:@selector(ratingChanged) withObject:nil afterDelay:RATING_SAVE_DELAY];
	[self performSelectorOnMainThread:@selector(updateRatingView) withObject:nil waitUntilDone:NO];
		
}

- (void) updateRatingView {
	
	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			 @"updateRatingView can only be done on the main thread.");
	
	MusicPlayerAppDelegate * appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];

	if(appDelegate.active) {
		CATransition *transition = [CATransition animation];
		transition.duration = 0.50;
		// using the ease in/out timing function
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		transition.type = kCATransitionFade;
		self.view.backgroundColor = [appDelegate.rootViewController ratingColor:self.rating];
		[self.view.layer addAnimation:transition forKey:nil];
	} 
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([keyPath isEqual:@"rating"]) {
		
		[self performSelectorOnMainThread:@selector(ratingChanged:) withObject:self.rating waitUntilDone:NO];
		
	} 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.rating = nil;
	self.ratingObjects = nil;
	self.parentController = nil;
	self.managedObject = nil;
	
	[self removeObserver:self forKeyPath:@"rating"];
				 
}


- (void)dealloc {
	[rating release];
	[ratingObjects release];
	[parentController release];
	[managedObject release];

    [super dealloc];
}


@end
