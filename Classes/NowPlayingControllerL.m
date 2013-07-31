//
//  Junk.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/07/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "NowPlayingControllerL.h"


@implementation NowPlayingControllerL

@synthesize trackName;
@synthesize bitRate;
@synthesize timePlayed;
@synthesize dataFormat;

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	self.trackName = nil;
	self.bitRate = nil;
	self.timePlayed = nil;
	self.dataFormat = nil;

}


- (void)dealloc {
	[trackName release];
	[bitRate release];
	[timePlayed release];
	[dataFormat release];
	
    [super dealloc];
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}
*/
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/




@end
