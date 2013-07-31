//
//  SongDetailView.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/16/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreEditingDetailView.h"
#import "SongRatingController.h"

@class SongsTabBarController;


@interface SongDetailView : CoreEditingDetailView  <UINavigationControllerDelegate, UITextFieldDelegate, CoreEditingDetailViewDelegate, UINavigationBarDelegate> {
	UILabel * songNameLabel, *artistLabel, *mixLabel, *ratingLabel, *topRatedLabel, *artistMixLabel;
	UILabel * songID, *addedOn, *lastServerRefresh, *topRated;
	
	UIView *ratingControllerContainer;
	SongRatingController * ratingController;
	
	UIView * containerView;
	UIImageView * wallpaper;


	UILabel * songName;
	UILabel * artist;
	UILabel * mix;
	
}
@property (nonatomic, retain) IBOutlet UIImageView * wallpaper;

@property (nonatomic, assign) IBOutlet UILabel * songNameLabel, * artistLabel, * mixLabel, *ratingLabel, *topRatedLabel, *artistMixLabel;
@property (nonatomic, retain) IBOutlet UILabel * songID, *addedOn, *lastServerRefresh, *topRated;

@property (nonatomic, retain) IBOutlet UIView * containerView;

@property (nonatomic, retain) IBOutlet UILabel * songName;
@property (nonatomic, retain) IBOutlet UILabel * artist;
@property (nonatomic, retain) IBOutlet UILabel * mix;

@property (nonatomic, retain) IBOutlet SongRatingController * ratingController;
@property (nonatomic, retain) IBOutlet UIView * ratingControllerContainer;

- (id) initWithSong: (NSManagedObject *) song;

@end

