//
//  SplashController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/31/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "SplashController.h"


@implementation SplashController

@synthesize wallpaper;
@synthesize logoView;

- (UIImage *) wallPaperImage:(UIInterfaceOrientation)forInterfaceOrientation {
	return (UIInterfaceOrientationIsPortrait(forInterfaceOrientation)) ? 
	[UIImage imageNamed:@"SplashWP.png"] :
	[UIImage imageNamed:@"SplashWL.png"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	wallpaper.image = [self wallPaperImage:[self interfaceOrientation]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	wallpaper.image = [self wallPaperImage:toInterfaceOrientation];
	//	NSLog(@"center = %@", NSStringFromCGRect(wallpaper.bounds));
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
		logoView.center = CGPointMake(160.0,208.0);
	} else {
		logoView.center = CGPointMake(240.0,128.0);
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.wallpaper = nil;
	self.logoView = nil;
}


- (void)dealloc {
	[wallpaper release];
	[logoView release];
    [super dealloc];
}


@end
