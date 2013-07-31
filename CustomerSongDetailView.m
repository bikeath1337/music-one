//
//  CustomerSongDetailView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 04/04/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "CustomerSongDetailView.h"
#import "Song.h"


@implementation CustomerSongDetailView

@synthesize logoView;

- (void)viewDidLoad {
	[super viewDidLoad];
	[self willAnimateRotationToInterfaceOrientation:[self interfaceOrientation] duration:0.0];
}

#pragma mark -
#pragma mark UIInterfaceOrientation Management

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
		//NSLog(@"from ToP center=%@", NSStringFromCGPoint(containerView.center));
		logoView.center = CGPointMake(100.0,68.0);
		logoView.frame = CGRectMake(5.0, -22.0, 200.0, 180.0);
		containerView.center = CGPointMake(160.0, 230.5);
		wallpaper.image = [UIImage imageNamed:@"TrackWP.png"];
	} else {
		//	NSLog(@"from ToL center=%@", NSStringFromCGPoint(containerView.center));
		containerView.center = CGPointMake(240.0, 134.0);
		CGRect frame = logoView.frame;
		frame.size.width *= 0.5;
		frame.size.height *= 0.5;
		logoView.frame = frame;
		logoView.center = CGPointMake(425.0,220.0);
		wallpaper.image = [UIImage imageNamed:@"TrackWL.png"];
	}
	
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
}

- (void) resizeLabel:(Song*) song label:(UILabel *) label songColumn:(NSString *) columnName {
	CGPoint center = label.center;
	CGFloat margin = 30.0;
	
	CGFloat width = [song getLabelWidth:label songColumn:columnName margin:margin];
	if (width > 290.0) {
		CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
		CGFloat screenWidth = UIInterfaceOrientationIsPortrait((self.interfaceOrientation)) ? screenFrame.size.width : screenFrame.size.height;
		width = screenWidth - 3 * margin;
	}
	
	CGRect labelrect = label.bounds;
	labelrect.size.width = width;
	[UIView beginAnimations:nil context:nil];
	
	UInt32 duration = 1.0;
	
	[UIView setAnimationDuration:duration];
	
	label.bounds = labelrect;
	label.text = [song valueForKey:columnName];
	label.center = center;
	
	//label.transform = CGAffineTransformMakeScale(1, 1);
	[UIView commitAnimations];
	
}

- (void) loadDataFromManagedObject {
	@synchronized(self) {
		
		Song * song = (Song *) managedObject;
		
		songID.text = [[managedObject valueForKey:@"songID"] stringValue];
		
		[self resizeLabel:song label:songName songColumn:@"name"];
		[self resizeLabel:song label:artist songColumn:@"artist"];
		[self resizeLabel:song label:mix songColumn:@"mix"];
		
		ratingController.serverState = [[managedObject valueForKey:@"ratingSent"] intValue];
		
		ratingController.rating = [managedObject valueForKey:@"rating"];
		
		UIColor * color = [appDelegate.rootViewController ratingColor:ratingController.rating];
		
		ratingControllerContainer.backgroundColor = color;
		[ratingController performSelector:@selector(updateRatingView) withObject:nil afterDelay:0.25];
		
		static NSDateFormatter *dateFormatter = nil;
		if (dateFormatter == nil) {
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateStyle:NSDateFormatterShortStyle];
			[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		}
		
		BOOL isTopRated = [[managedObject valueForKey:@"topSong"] boolValue];
		if (isTopRated) {
			topRated.text = [NSLocalizedStringFromTable(@"IsTopRated", @"App", nil) uppercaseString];
			topRated.hidden = NO;
		} else {
			topRated.hidden = YES;
		}

		addedOn.text = [dateFormatter stringFromDate:[managedObject valueForKey:@"addedOnTimestamp"]];
		lastServerRefresh.text = [dateFormatter stringFromDate:[managedObject valueForKey:@"lastRefresh"]];
	}
}

- (void)viewDidUnload {
	self.logoView = nil;
}


- (void)dealloc {
	[logoView release];
    [super dealloc];
}

@end
