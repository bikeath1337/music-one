//
//  CustomerSongDetailView.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 04/04/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongDetailView.h"


@interface CustomerSongDetailView : SongDetailView {
	UIImageView * logoView;

}
@property (nonatomic, retain) IBOutlet UIImageView * logoView;

@end
