//
//  Junk.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/07/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NowPlayingControllerL : UIViewController {
	
	UITextView * trackName;
	UILabel * bitRate;
	UILabel * timePlayed;
	UILabel * dataFormat;
}

@property (nonatomic, retain) IBOutlet UITextView * trackName;
@property (nonatomic, retain) IBOutlet UILabel * bitRate;
@property (nonatomic, retain) IBOutlet UILabel * timePlayed;
@property (nonatomic, retain) IBOutlet UILabel * dataFormat;

@end
