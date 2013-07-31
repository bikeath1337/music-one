//
//  BandwidthController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 03/30/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BandwidthController : UIViewController {

	UILabel *formatLabel;
	UILabel *bitRateLabel;
}

@property (retain, nonatomic) IBOutlet UILabel *formatLabel, *bitRateLabel;
@end
