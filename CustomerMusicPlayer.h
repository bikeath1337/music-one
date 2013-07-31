//
//  CustomerMusicPlayer.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/18/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#define USE_DUMMY_SONGSTRING 0

#import <UIKit/UIKit.h>
#import "MusicPlayerController.h"
#import "IniPreferences.h"

@class IniPreferences;

@interface CustomerMusicPlayer : MusicPlayerController <MusicPlayerDelegate>{
	IniPreferences * iniMissedData, *iniTopData;
}

@property (nonatomic, retain) IniPreferences * iniMissedData, *iniTopData;

//- (NSString *) encodeData:(NSString *) data;
- (NSString *) decodeData:(NSString *) data;
//- (NSString *) encodeSong:(NSString *) song;
//- (NSString *) decodeSong:(NSString *) song;



@end
