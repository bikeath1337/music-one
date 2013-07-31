//
//  CustomerNowPlayingViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 04/01/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "CustomerNowPlayingViewController.h"

@implementation CustomerNowPlayingViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	nowPlayingLabel.text = [nowPlayingLabel.text uppercaseString];
	[self resizeLabel:nowPlayingLabel text:nowPlayingLabel.text];
	rateItLabel.text = [rateItLabel.text uppercaseString];
	
	[self performSelector:@selector(setLabelsToZero)];
}

- (void) viewDidUnload {
	[super viewDidUnload];
}

- (void) dealloc {
	[super dealloc];
}

- (UIImage *) wallPaperImage:(UIInterfaceOrientation)forInterfaceOrientation {
	return (UIInterfaceOrientationIsPortrait(forInterfaceOrientation)) ? 
	[UIImage imageNamed:@"NowPlayingWP.png"] :
	[UIImage imageNamed:@"NowPlayingWL.png"];
}

- (CGFloat) labelWidth:(UILabel *) label text:(NSString *) text {
	CGFloat margin = 15.0;
	
	CGFloat width = 0;
	if([text length]) {
		width = [text sizeWithFont:label.font].width + margin;
	}
	
	if (width > 290.0) {
		CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
		CGFloat screenWidth = UIInterfaceOrientationIsPortrait((self.interfaceOrientation)) ? screenFrame.size.width : screenFrame.size.height;
		width = screenWidth - 3 * margin;
	}
	
	return width;
}

- (void) resizeLabel:(UILabel *) label text:(NSString *) text {
	CGFloat oldWidth = label.bounds.size.width;
	
	CGFloat width = [self labelWidth:label text:text];

	CGPoint center = label.center;
	CGRect labelrect = label.bounds;
	
	labelrect.size.width = width;
	
	[UIView beginAnimations:nil context:nil];
	
	UInt32 duration = 1.0;
	
	[UIView setAnimationDuration:duration];
	
	label.bounds = labelrect;
	center.x += (width - oldWidth)/2.0;
	label.text = text;
	label.center = center;
	
	[UIView commitAnimations];
	
}
- (UILabel *) leftBorderLabel:(UILabel *) label {
	return (UILabel *)[self.view viewWithTag:label.tag + 20];
}

- (void) resizeSongLabel:(Song*) song label:(UILabel *) label songColumn:(NSString *) columnName {
	[self resizeLabel:label text:[song valueForKey:columnName]];
	[self leftBorderLabel:label].hidden = (label.text.length == 0);
}

- (void) songToUI {
	[super songToUI];
	
	Song * song = (Song *) nowPlayingSong;
	
	[self resizeSongLabel:song label:songName songColumn:@"name"];
	[self resizeSongLabel:song label:artist songColumn:@"artist"];
	[self resizeSongLabel:song label:mix songColumn:@"mix"];
	[self resizeLabel:timePlayed text:@"00:00:00"];
	
}
- (void) zeroLabelWidth:(UILabel *) label {
	CGRect frame = label.frame;
	frame.size.width = 0;
	label.frame = frame;

	[self leftBorderLabel:label].hidden = YES;
}

- (void) setLabelsToZero {
	
	[self zeroLabelWidth:songName];
	[self zeroLabelWidth:artist];
	[self zeroLabelWidth:mix];
	[self zeroLabelWidth:timePlayed];
	
}

#pragma mark -
#pragma mark UIInterfaceOrientation Management

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	wallpaper.image = [self wallPaperImage:toInterfaceOrientation];
	
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
		containerContentView.frame = CGRectMake(0, -14, 320, 460);
		bottomView.center = CGPointMake(160.0,318.0);
		logoView.center = CGPointMake(100.0,90.0);
		logoView.frame = CGRectMake(5.0, -22.0, 200.0, 180.0);
		//		NSLog(@"portrait np centered: %@", NSStringFromCGRect(containerContentView.frame));
	} else {
		containerContentView.frame = CGRectMake(0, -110, 320, 460);
		bottomView.center = CGPointMake(155.0,310.0);
		logoView.center = CGPointMake(410.0,215.0);
		CGRect frame = logoView.frame;
		NSLog(@"size: %@", NSStringFromCGRect(frame));
		frame.size.width = 170;
		frame.size.height = 153;
		logoView.frame = frame;
		//		NSLog(@"landscape np centered: %@", NSStringFromCGRect(containerContentView.frame));

	}
	
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
	if (!appDelegate.active) {
		return;
	}
	
}

@end
