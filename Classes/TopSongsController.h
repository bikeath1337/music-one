//
//  TopSongsController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/19/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SongTableViewController.h"
#import "PlayerEventNotifications.h"

@interface TopSongsController : SongTableViewController {
	UIButton *rankButtonTemplate;

}

@property (nonatomic, retain) IBOutlet UIButton * rankButtonTemplate;

@end
