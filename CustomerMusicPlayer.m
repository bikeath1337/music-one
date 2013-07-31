//
//  CustomerMusicPlayer.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/18/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CustomerMusicPlayer.h"
#import "SongPickerView.h"
#import "PlayerEventNotifications.h"
#import "CustomerNowPlayingViewController.h"
#import "SplashController.h"

@implementation CustomerMusicPlayer

@synthesize iniMissedData, iniTopData;

- (id) init {
	if( self = [super init] ){
		self.playerDelegate = self;
		self.onColor = [UIColor colorWithRed:211.0/255.0 green:21.0/255.0 blue:146.0/255.0 alpha: 1.0]; // hot pink
		self.offColor = [UIColor colorWithRed:16.0/255.0 green:212.0/255.0 blue:254.0/255.0 alpha: 1.0]; // blue

	}
	return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
	if(self = [super initWithCoder:decoder]) {
		self.playerDelegate = self;
	}
	return self;
}

- (NSString *) nowPlayingPortraitNib {
	return @"NowPlayingViewController";
}
- (NSString *) nowPlayingLandscapeNib {
	return @"NowPlayingViewController";
}
- (NSString *) songDetailNib {
	return @"SongDetailView";
}
- (void) customizeStartupView {
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	//[self.navigationController setNavigationBarHidden:YES animated:NO];
	appDelegate.window.backgroundColor = offColor;
	scrollView.backgroundColor = onColor;
	//reachabilitySource.textColor = [UIColor whiteColor];
#if DEBUG_SCREEN
	playerStatus.textColor = [UIColor whiteColor];
#endif
	//autoLockDisabled.textColor = [UIColor whiteColor];
	//reachabilitySource.backgroundColor = [UIColor blackColor];
}

- (void) customizeNavigationController:(UINavigationController *) navigationController {
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	navigationController.toolbar.tintColor = onColor;
}

- (void) updateCustomNavigation: (BOOL) animated {
}

- (UIColor *) ratingColor:(NSNumber *) songRating {
	return ([songRating integerValue]) ? onColor : offColor;
}

- (void)showSplash{
	
	UIView *newView = self.splashController.view;
	
	if (newView.superview == nil) {
		newView.frame = scrollView.frame;
	}
	
	CATransition *transition = [CATransition animation];
	
	transition.duration = 1.00;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
	
	[containerView.layer addAnimation:transition forKey:nil];
	
	UIView * visibleView = ([containerView.subviews count]) ? [containerView.subviews objectAtIndex:0] : nil;
	[nowPlayingController performSelector:@selector(setLabelsToZero)];
	[visibleView removeFromSuperview];

	[containerView addSubview:newView];
	[splashController willAnimateRotationToInterfaceOrientation:[self interfaceOrientation] duration:0.0];
	
}

- (void)showNowPlayingSong {
	
	// disable user interaction during the flip
	UIView * newView = self.nowPlayingController.view;
	
	newView.alpha = 1.0;
	
	CATransition *transition = [CATransition animation];
	transition.delegate = nowPlayingController;
	
	transition.duration = 1.00;
	// using the ease in/out timing function
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
	
	[containerView.layer addAnimation:transition forKey:nil];
	
	UIView * visibleView = ([containerView.subviews count]) ? [containerView.subviews objectAtIndex:0] : nil;
	[visibleView removeFromSuperview];
	
	if (newView.superview == nil) {
		[containerView addSubview:newView];
		[nowPlayingController willAnimateRotationToInterfaceOrientation:[self interfaceOrientation] duration:0.0];
	} else {

	}
	
}

-(void) trackChangedToNewSong {
	
	if (nowPlayingController.timePlayed.frame.size.width == 0) {
		// Fields are already zero'd out, so don't do it again.
		[self trackChanged];
		return;
	}

	CATransition *transition = [CATransition animation];
	
	transition.duration = 1.00;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.delegate = self;
	
	transition.type = kCATransitionFade;
	
	[containerView.layer addAnimation:transition forKey:nil];
	
	[nowPlayingController performSelector:@selector(setLabelsToZero)];
	
	containerView.hidden = YES;
	containerView.hidden = NO;
	
}
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	if(userAction == ASC_STARTPLAY) {
		[self trackChanged];
	} else {
		[self showSplash];
	}

}

-(void)trackChanged {
	CATransition *transition = [CATransition animation];
	
	transition.duration = 1.00;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	transition.type = kCATransitionFade;
	
	[containerView.layer addAnimation:transition forKey:nil];
	
	[nowPlayingController songToUI];
	
	containerView.hidden = YES;
	containerView.hidden = NO;
	
}


- (void) vote:( NSArray *) args  {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSNumber * songIDStr = [args objectAtIndex:0];
	NSNumber * rating = [args objectAtIndex:1];
	NSManagedObjectID * objectID = [args objectAtIndex:2];
	
	NSString * voteFmt = @"http://app.musicone.fm/mobile/rtm_mobile.php?song_id=%d&vote=%d&datetime=%f&did=%@&platform=1";
    
	@try {
        songIDStr = [args objectAtIndex:0];
        rating = [args objectAtIndex:1];
        objectID = [args objectAtIndex:2];
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        
        NSString * deviceID = [[UIDevice currentDevice] uniqueIdentifier];
        
        // Drupal rating is 0, 20, 40, 60, 80, 100
        NSString * voteURL = [NSString stringWithFormat:voteFmt, [songIDStr intValue], [rating intValue] * 20, now, deviceID];
        
        NSError *error = nil;
        NSString *response = [NSString stringWithContentsOfURL:[NSURL URLWithString:voteURL] encoding:NSUTF8StringEncoding error:&error];
        if ([response length]){
            response = [response stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            if ([response isEqual:@"1"]) {
                // Success!
                //NSLog(@"Vote recorded");
                NSArray * argus = [NSArray arrayWithObjects:objectID, [NSNumber numberWithInt:songVoteRecordedYes], nil];
                [self performSelectorOnMainThread:@selector(voteRecorded:) withObject:argus waitUntilDone:NO];
            } else {
                // Failure
                NSLog(@"Vote failed");
                NSArray * argus = [NSArray arrayWithObjects:objectID, [NSNumber numberWithInt:songVoteRecordedNo], nil];
                [self performSelectorOnMainThread:@selector(voteRecorded:) withObject:argus waitUntilDone:NO];
            }
        }
	} 
	@catch (id theException) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        
        NSString * deviceID = [[UIDevice currentDevice] uniqueIdentifier];
        NSString * voteURL = [NSString stringWithFormat:voteFmt, [songIDStr intValue], [rating intValue] * 20, now, deviceID];
        // Failure
        NSLog(@"Vote failed -- exception - %@", voteURL);
	} 
	@finally {
	}
	
	[pool drain];
}

- (NSDate *) convertToLocaleDate:(NSDate *) dateToConvert fromTimeZone:(NSTimeZone *) fromTimeZone {
	// calculate offset seconds from station's time zone to locale's time zone
	// The server time zone richard sends is GMT from NY Time
	NSTimeInterval tzSecondsFromGMT = [fromTimeZone secondsFromGMT];
	
	NSTimeZone * NYCTz = [NSTimeZone timeZoneWithName:@"America/New_York"];
	NSTimeZone * localeTimeZone = [[NSCalendar currentCalendar] timeZone];
	
	NSTimeInterval localeSecondsFromGMT = [localeTimeZone secondsFromGMT];
	NSTimeInterval NYCSecondsFromGMT =[NYCTz secondsFromGMT];;

	NSTimeInterval localeSecondsFromNYC = localeSecondsFromGMT - NYCSecondsFromGMT;
	
	//	NSLog(@" befre %@", dateToConvert);
	dateToConvert = [dateToConvert dateByAddingTimeInterval:-localeSecondsFromNYC];

	//	NSLog(@"after %@", dateToConvert);
	
	return [dateToConvert dateByAddingTimeInterval:localeSecondsFromGMT - tzSecondsFromGMT ];
}

- (NSDate *) refreshDate { // Sunday 20h00
	NSCalendar *stationCalendar = [NSCalendar currentCalendar];
	NSTimeZone *stationTimeZone = [NSTimeZone timeZoneWithName:appDelegate.theStation.timeZoneID];

	NSDateComponents *stationNowComponents =[stationCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:[NSDate date]];
	
	NSInteger weekdayNow = [stationNowComponents weekday];
	
	[stationNowComponents setHour:20];
	
	NSDate *sunday20h00 = [stationCalendar dateFromComponents:stationNowComponents];
	
	NSInteger offset = -(weekdayNow - 1);
	NSDate * stationRefreshTime = [sunday20h00 dateByAddingTimeInterval:offset*DAY_IN_SECONDS];
	
	return [self convertToLocaleDate:stationRefreshTime fromTimeZone:stationTimeZone];
}

- (NSDate *) voteClearDate { 
	// Sunday 00h00 New York Time
	NSCalendar *stationCalendar = [NSCalendar currentCalendar];
	NSTimeZone *stationTimeZone = [NSTimeZone timeZoneWithName:appDelegate.theStation.timeZoneID];

	// set calendar to timezone of the station
	[stationCalendar setTimeZone:stationTimeZone];
	
	NSDateComponents *stationNowComponents =[stationCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:[NSDate date]];
	
	NSInteger weekdayNow = [stationNowComponents weekday];
	
	NSDate *sunday00h00 = [stationCalendar dateFromComponents:stationNowComponents];
	
	NSInteger offset = -(weekdayNow - 1);
	NSDate * voteClearDateStation = [sunday00h00 dateByAddingTimeInterval:offset*DAY_IN_SECONDS];
	
	return [self convertToLocaleDate:voteClearDateStation fromTimeZone:stationTimeZone];
	
}

- (BOOL) topSongsAreRefreshed:(NSDate *)lastRefreshedOn {
	
	// Refresh after Sunday 20h00 Midnight
	NSDate * now = [NSDate date];
	
	NSInteger offset = [now timeIntervalSinceDate:lastRefreshedOn];
	// 86,400 = 1 day, 604,800 = 7 days
	if (offset >= WEEK_IN_SECONDS) { // more than one week has passed, no, data is not fresh
		return NO;
	}
	
	NSDate *freshDate = [self refreshDate];
	
	offset = [lastRefreshedOn timeIntervalSinceDate:freshDate];
	if(offset <= 0){ // Data is not fresh as it has not been refreshed since the previous monday at midnight
		return NO;
	}
	
	return YES;
}
- (NSDate *) topSongsDate {
	NSDate * lastRefresh = [self refreshDate];
	// Songs are for the PREVIOUS week 
	return[lastRefresh dateByAddingTimeInterval:-(DAY_IN_SECONDS*7)];
}

- (NSString *) getShoutCastStreamDataBit:(NSString *) streamData open:(NSString *)open {
	NSArray * a1 = [streamData componentsSeparatedByString:open];
	if (![a1 count]) {
		return nil;
	}
	NSString *keyData = [a1 objectAtIndex:1];
	a1 = [keyData componentsSeparatedByString:@"';"];
	if (![a1 count]) {
		return nil;
	}

	return [a1 objectAtIndex:0];
}

-(Song *)createSong:(NSString *)trackName {

	// Now find SongID
	NSString * streamUrl = [self getShoutCastStreamDataBit: trackName open:@"StreamUrl='"];
    NSString * protocol;

	@try {
        protocol = [[streamUrl substringWithRange:(NSRange) {0,4}] lowercaseString];
	} 
	@catch (id theException) {
        protocol = @"";
	} 
	@finally {
	}
	
	NSString * thisSongID = nil;

	if([protocol isEqual:@"http"]) {
		NSURL * url = [NSURL URLWithString:streamUrl];
		NSString * query = [url query];

		//http://www.m1live.com/?songid=1234
		
		NSArray * pairs = [query componentsSeparatedByString:@"&"];
		for (NSString *pair in pairs) {
			NSArray * data = [pair componentsSeparatedByString:@"="];
			NSString *key = [[data objectAtIndex:0] lowercaseString];
			if ([key isEqual:@"songid"]) {
				thisSongID = [data objectAtIndex:1];
				break;
			}
		}
		if(thisSongID == nil)
			return nil;
	} else {
		thisSongID = [self getShoutCastStreamDataBit: trackName open:@"StreamUrl='"];
	}

	if([thisSongID isEqualToString:self.songID]) {
		//		NSLog(@"song changed to same song");
		return self.nowPlayingSong;
	}
	
	NSString *songName = [self getShoutCastStreamDataBit: trackName open:@"StreamTitle='"];
	songName = [songName stringByReplacingOccurrencesOfString:@" * Rate The Music at www.m1live.com/music *';" withString:@""];
	
	Song * song = [self getNowPlayingSong:thisSongID trackName:songName];
	
/*	
	NSLog(@"name=%@", [song valueForKey:@"name"]);
	NSLog(@"artist=%@", [song valueForKey:@"artist"]);
	NSLog(@"mix=%@", [song valueForKey:@"mix"]);
*/
	return song;
}

-(NSManagedObject *)createStation:(NSManagedObject *)newStation {

	[newStation setValue:@"Music One" forKey:@"stationName"];
	[newStation setValue:@"Dance Radio scene bridging the wide gap between commercial radio and the dance floor" forKey:@"stationDescription"];
	[newStation setValue:@"http://www.musicone.fm" forKey:@"webSiteUrl"];
	[newStation setValue:@"feedback@musiconeradio.com" forKey:@"stationEmailAddress"];
	[newStation setValue:@"America/New_York" forKey:@"timeZoneID"];
	
	return newStation;
}
-(NSArray *)createStreamOptions {
	NSManagedObject * option= [NSEntityDescription insertNewObjectForEntityForName:@"StreamOption" inManagedObjectContext:managedObjectContext];

	NSMutableArray * mutableOptions = [NSMutableArray array];
	
	// These must be created in order so they display correctly in the list (prevents resorting and refetching)
	[option setValue:[NSNumber numberWithInt:10] forKey:@"priority"];
	[option setValue:[NSNumber numberWithInt:kAudioFileMP3Type] forKey:@"streamType"];
	[option setValue:@"audio/mpeg" forKey:@"contentType"];
	[option setValue:@"WIFI Quality" forKey:@"streamDescription"];
	[option setValue:@"WIFI bps" forKey:@"bpsDescription"];
	[option setValue:@"http://app.musicone.fm/mobile/mp3_128.pls" forKey:@"playlistUrl"];
	[option setValue:[NSNumber numberWithInt:SS_TYPE_SHOUTCAST] forKey:@"serverType"];
	[option setValue:[NSNumber numberWithBool:YES] forKey:@"icyMetaTitleCompliant"];
	[option setValue:@"GMT" forKey:@"serverTimeZone"];
	//	[option setValue:@"America/New_York" forKey:@"serverTimeZone"];
	
	[mutableOptions addObject: option];
	
	option= (StreamOption *)[NSEntityDescription insertNewObjectForEntityForName:@"StreamOption" inManagedObjectContext:managedObjectContext];

	[option setValue:[NSNumber numberWithInt:20] forKey:@"priority"];
	[option setValue:[NSNumber numberWithInt:kAudioFileAAC_ADTSType] forKey:@"streamType"];
	[option setValue:@"audio/aacp" forKey:@"contentType"];
	[option setValue:@"EDGE Quality" forKey:@"streamDescription"];
	[option setValue:@"EDGE bps" forKey:@"bpsDescription"];
	[option setValue:@"http://app.musicone.fm/mobile/aac_48.pls" forKey:@"playlistUrl"];
	[option setValue:[NSNumber numberWithInt:SS_TYPE_SHOUTCAST] forKey:@"serverType"];
	[option setValue:[NSNumber numberWithBool:YES] forKey:@"icyMetaTitleCompliant"];
	[option setValue:@"GMT" forKey:@"serverTimeZone"];
	//	[option setValue:@"America/New_York" forKey:@"serverTimeZone"];
	
	[mutableOptions addObject: option];
	
	return [NSArray arrayWithArray:mutableOptions];
}
- (NSString *) aboutURL {
	return NSLocalizedStringFromTable(@"AboutURL", @"Owner", nil);
}
- (NSString *) supportURL {
	return NSLocalizedStringFromTable(@"SupportURL", @"Owner", nil);
}
- (NSString *) missedSongsURL {
return @"";
}
- (NSString *) topSongsURL {
	return @"";
}
- (NSString *) songDataURL:(NSString *) songid {
	return [NSString stringWithFormat:@"http://app.musicone.fm/mobile/songdata.php?id=%@", songid];
}

- (void) startCreateTopSongs: (SongPickerView *) notify {
	if(!self.reachable) {
		return;
	}
	NSString * url = @"http://app.musicone.fm/mobile/top20.php";
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	self.iniTopData = [[IniPreferences alloc] initWithString:url encoding: NSUTF8StringEncoding];
	
 	if(iniTopData != nil) {
		[self createTopSongsBackground:notify];
	}
	
	self.iniTopData = nil;
	
	[pool drain];
	
}
- (void) startCreateMissedSongs: (SongPickerView *) notify {
	
	if(!self.reachable) {
		return;
	}
	
	NSString * url = @"http://app.musicone.fm/mobile/recentsongs.php";
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	self.iniMissedData = [[IniPreferences alloc] initWithString:url encoding: NSUTF8StringEncoding];

	if(iniMissedData != nil) {
		[self createMissedSongsBackground:notify];
	}
	
	self.iniMissedData = nil;
	
    [pool drain];
	
}
- (NSArray *) createSongList:(IniPreferences *) iniData sectionKey:(NSString *) dataSectionKey boolKey:(NSString *) boolKey processedMissed:(BOOL) processedMissed {
	
	NSDictionary *songListData = [iniData.sections objectForKey:dataSectionKey];
	NSString *countOfItems = [songListData objectForKey:@"count"];
	NSUInteger count = [countOfItems integerValue];
	
	NSMutableArray *songs = [NSMutableArray arrayWithCapacity:count];
	Song *song;
	
	for (NSUInteger i=1; i<=count; i++) {
		NSString *key = [@"song" stringByAppendingString:[[NSNumber numberWithInt:i] stringValue]];
		NSString *songStr = [songListData objectForKey:key];
		//NSLog(@"Encoded key=%@ %@", key, songStr);
		//NSString *decodedSong = [self decodeSong:songStr];
		//NSLog(@"Decoded Song = %@", decodedSong);
		
		NSDictionary * songDict = [self songDictionaryFromString:songStr processMissed:processedMissed];
		if(songDict == nil) {
			NSLog(@"No song ID found in data.");
		} else {
			song = [self songFromDictionary:songDict processMissed:processedMissed];
			[song setValue:[NSNumber numberWithBool:YES] forKey:boolKey];
			[songs addObject:song];
		}

	}
	
	return [NSArray arrayWithArray:songs];
}

- (NSArray *) localCreateTopSongs {
	NSDictionary *songListData = [iniTopData.sections objectForKey:@"top songs"];
	
	// Get date timestamp of when the station created the top songs file
	NSString * dateStr = [songListData objectForKey:@"asofdate"];
	if ([dateStr length]) {
		NSTimeInterval since1970 = [dateStr doubleValue];
		NSDate * asOfDate = [NSDate dateWithTimeIntervalSince1970:since1970];
		NSDate * lastTopSongsStationTimestamp = [[NSUserDefaults standardUserDefaults] objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsStationTimestamp]];

		if (lastTopSongsStationTimestamp != nil && [asOfDate isEqualToDate:lastTopSongsStationTimestamp]) {
			return nil; // no changes
		}
		// store new date
		if (asOfDate == nil) {
			asOfDate = [self topSongsDate];
		}
		[[NSUserDefaults standardUserDefaults] setObject:asOfDate forKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsStationTimestamp]];
	}
	

	NSArray * result = 	[self createSongList:iniTopData sectionKey:@"top songs" boolKey:@"topSong" processedMissed:NO];
	
	NSInteger idx = 1;
	for (NSManagedObject * song in result) {
		[song setValue:[NSNumber numberWithInt:idx++] forKey:@"topSongSequence"];
	}
	
	return result;
}

- (NSArray *) localCreateMissedSongs{
	return [self createSongList:iniMissedData sectionKey:@"missedsongs" boolKey:@"missed" processedMissed:YES];
}

- (NSString *) stripMixBrackets:mix open:(NSString *) lBracket close:(NSString *) rBracket {
	NSRange loc = [mix rangeOfString:lBracket];
	if(loc.location == 0) {
		loc = [[mix substringFromIndex:1] rangeOfString:rBracket];
		if (loc.location != NSNotFound && loc.location == [mix length]-2) {
			loc.location=1;
			loc.length = [mix length] -2;
			mix = [mix substringWithRange:loc];
		}
		return mix; // stripped
	}
	return mix; // no changes
}

- (NSDictionary *) songDictionaryFromString:(NSString *) encodedSongData processMissed:(BOOL) processMissed {

	//NSLog(@"Song from server %@", encodedSongData);
	
	NSArray * songData = [encodedSongData componentsSeparatedByString:@";"];
	
	NSMutableDictionary *songDataDict = [NSMutableDictionary dictionary];
	for (NSString * dataBit in songData) {
		NSArray * dataPair = [dataBit componentsSeparatedByString:@"="];
		//NSLog(@"key=%@, Value=%@", [dataPair objectAtIndex:0], [dataPair objectAtIndex:1]);
		[songDataDict setValue:[self decodeData:[dataPair objectAtIndex:1]] forKey:[dataPair objectAtIndex:0]];
	}
	
	NSString * newSongID = [songDataDict objectForKey:@"songID"];
	if ([newSongID intValue] == 0) {
		if(!TARGET_IPHONE_SIMULATOR) {
			return nil; // song not found. Song must have a positive int ID
		}
		if(USE_DUMMY_SONGSTRING == 1) {
			NSString * songString = @"songID%99993E%3Bname%3EName of Song%3Bartist%3EBobby Wallace%3Bmix%3ENYC Chelsea Mix%3Btimestamp%3E";
			return [self songDictionaryFromString:songString processMissed:processMissed];
		} else {
			return nil;
		}
	}
	// clean up Mix by removing enclosing brackets and parentheses
	NSString *mix = [[songDataDict objectForKey:@"mix"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	mix = [self stripMixBrackets:mix open:@"[" close:@"]"];
	mix = [self stripMixBrackets:mix open:@"(" close:@")"];

	[songDataDict setValue:mix forKey:@"mix"];
	
	if (processMissed) {
		
		NSDate * timestamp = [NSDate dateWithTimeIntervalSince1970:[[songDataDict valueForKey:@"timestamp"] intValue]];
		NSDate * dte = [self convertToLocaleDate:timestamp 
									fromTimeZone:[NSTimeZone timeZoneWithName:appDelegate.streamOption.serverTimeZone]];
		//		NSLog(@"tz=%@, %@, %@",appDelegate.streamOption.serverTimeZone, timestamp, dte);
		[songDataDict setObject:dte forKey:@"missedDate"];
		
	}
	
	return [NSDictionary dictionaryWithDictionary:songDataDict];
}
/*
- (NSString *) encodeData:(NSString *) data {
	NSString * encodedData = [data stringByReplacingOccurrencesOfString:@"=" withString:@"%3E"];
	encodedData = [encodedData stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
	encodedData = [encodedData stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
	encodedData = [encodedData stringByReplacingOccurrencesOfString:@";" withString:@"%3B"];
	return encodedData;
}
*/

- (NSString *) decodeData:(NSString *) data{
	NSString * decodedData = [data stringByReplacingOccurrencesOfString:@"%3E" withString:@"="];
	decodedData = [decodedData stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
	decodedData = [decodedData stringByReplacingOccurrencesOfString:@"%25" withString:@"%"];
	decodedData = [decodedData stringByReplacingOccurrencesOfString:@"%3B" withString:@";"];
	return decodedData;
}
/*
- (NSString *) encodeSong:(NSString *) song{
	NSString* encodedSong = [song stringByReplacingOccurrencesOfString:@"=" withString:@"%3E"];
	return encodedSong;
}

- (NSString *) decodeSong:(NSString *) song{
	NSString *decodedSong = [song stringByReplacingOccurrencesOfString:@"%3E" withString:@"="];
	decodedSong = [decodedSong stringByReplacingOccurrencesOfString:@"%3B" withString:@";"];
	return decodedSong;
}
*/

- (NSString *) backButtonImageName {
	return @"BackArrow.png";
}

- (NowPlayingViewController *) nowPlayingController {
	
    if (nowPlayingController != nil) {
        return nowPlayingController;
    }
	
	nowPlayingController = [[CustomerNowPlayingViewController alloc] initWithNibName:@"NowPlayingViewController" bundle:nil];
	
	return nowPlayingController;
}


@end
