//
//  SplashController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/31/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SplashController : UIViewController {
	UIImageView * wallpaper;
	UIImageView * logoView;
}
@property (nonatomic, retain) IBOutlet UIImageView * wallpaper;
@property (nonatomic, retain) IBOutlet UIImageView * logoView;

- (UIImage *) wallPaperImage:(UIInterfaceOrientation)forInterfaceOrientation;

@end
