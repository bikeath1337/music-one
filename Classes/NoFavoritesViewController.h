//
//  NoFavoritesViewController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/27/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NoFavoritesViewController : UIViewController {
	UITextView * noFavoritesTextView;
}

@property (assign, nonatomic) IBOutlet UITextView * noFavoritesTextView;

@end
