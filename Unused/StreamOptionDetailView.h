//
//  StreamOptionDetailView.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/15/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreEditingDetailView.h"


@interface StreamOptionDetailView : CoreEditingDetailView <UINavigationControllerDelegate, UITextFieldDelegate>{
	UITextField * priority;
	UITextField * playlistUrl;
	UITextField * urlString;
	UISwitch * icyMetaTitleCompliant;
	UITextField * streamType;
	UITextField * serverType;
	UITextField * contentType;
	UITextField * streamDescription;
}

@property (nonatomic, retain) IBOutlet UITextField * priority;
@property (nonatomic, retain) IBOutlet UITextField * playlistUrl;
@property (nonatomic, retain) IBOutlet UITextField *  urlString;
@property (nonatomic, retain) IBOutlet UISwitch *  icyMetaTitleCompliant;
@property (nonatomic, retain) IBOutlet UITextField * streamType;
@property (nonatomic, retain) IBOutlet UITextField * serverType;
@property (nonatomic, retain) IBOutlet UITextField * contentType;
@property (nonatomic, retain) IBOutlet UITextField * streamDescription;

@end
