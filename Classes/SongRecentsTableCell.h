//
//  SongRecentsTableCell.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/20/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SongRecentsTableCell : UITableViewCell {
	UILabel *songName;
	UILabel *artistMix;
	UILabel *when;
}

@property (nonatomic, retain) UILabel * songName;
@property (nonatomic, retain) UILabel * artistMix;
@property (nonatomic, retain) UILabel * when;
@end
