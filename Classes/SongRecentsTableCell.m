//
//  SongRecentsTableCell.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/20/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "SongRecentsTableCell.h"


@implementation SongRecentsTableCell

@synthesize songName;
@synthesize artistMix;
@synthesize when;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


@end
