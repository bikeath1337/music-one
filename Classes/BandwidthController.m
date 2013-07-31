//
//  BandwidthController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/30/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "BandwidthController.h"


@implementation BandwidthController

@synthesize formatLabel, bitRateLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	self.formatLabel = nil;
	self.bitRateLabel = nil;
}


- (void)dealloc {
	[formatLabel release];
	[bitRateLabel release];
    [super dealloc];
}


@end
