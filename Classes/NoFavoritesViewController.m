//
//  NoFavoritesViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/27/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "NoFavoritesViewController.h"


@implementation NoFavoritesViewController

@synthesize noFavoritesTextView;

- (void)viewDidLoad {
    [super viewDidLoad];
		
	self.noFavoritesTextView.text = NSLocalizedStringFromTable(@"NoFavorites", @"Tables", nil);
	noFavoritesTextView.contentMode = UIViewContentModeCenter;
	noFavoritesTextView.textColor = [UIColor whiteColor];
	
	self.view.backgroundColor = [UIColor clearColor];
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.noFavoritesTextView = nil;
}


- (void)dealloc {
	[noFavoritesTextView release];
    [super dealloc];
}


@end
