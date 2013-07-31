//
//  Junk.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/24/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "PlayerEventNotifications.h"


@implementation PlayerEventNotifications

+ (NSString *) keyForStatus: (AudioStreamerStatusRecoveryTypes) status {
	switch (status) {
		case AudioStreamerFetchMissedSongs:
			return @"AudioStreamerFetchMissedSongs";
		case AudioStreamerTopSongsAreFresh:
			return @"AudioStreamerTopSongsAreFresh";
		case AudioStreamerTopSongsLastFetchDate:
			return @"AudioStreamerTopSongsLastFetchDate";
		case AudioStreamerTopSongsStationTimestamp:
			return @"AudioStreamerTopSongsStationTimestamp";
		case AudioStreamerLastVoteCleanupDate:
			return @"AudioStreamerLastVoteCleanupDate";
		case AudioStreamerLastCleanupDate:
			return @"AudioStreamerLastCleanupDate";
		case AudioStreamerStationCreatedKey:
			return @"AudioStreamerStationCreatedKey";
		case AudioStreamerRecentsIndex:
			return @"AudioStreamerRecentsIndex";
		case AudioStreamerHTMLAbout:
			return @"AudioStreamerHTMLAbout";
		case AudioStreamerHTMLSupport:
			return @"AudioStreamerHTMLSupport";
		case AudioStreamerMoreDetail:
			return @"AudioStreamerMoreDetail";
		case AudioStreamerPlayState:
			return @"AudioStreamerPlayState";
		case StartupRestoreNavigationStack:
			return @"StartupRestoreNavigationStack";
		case StartupRestoreScrollPage:
			return @"StartupRestoreScrollPage";
		case StartupRestorePreferencesScrollFrame:
			return @"StartupRestorePreferencesScrollFrame";
		case StartupRestoreTabIndex:
			return @"StartupRestoreTabIndex";
		case StartupRestoreTableVisibleRange:
			return @"StartupRestoreTableVisibleRange";
		case StartupRestoreDetailSongID:
			return @"StartupRestoreDetailSongID";
		case StartupRestoreMailPickerChosen:
			return @"StartupRestoreMailPickerChosen";
		case StartupRestoreStationIndexKey:
			return @"StartupRestoreStationIndexKey";
		case StartupRestoreHTMLViewChosen:
			return @"StartupRestoreHTMLViewChosen";
		case StartupRestoreSongTableSelectedRow:
			return @"StartupRestoreSongTableSelectedRow";
		case StartupRestoreShowingPreferences:
			return @"StartupRestoreShowingPreferences";
		case StartupRestorePreferencesVisibleController:
			return @"StartupRestorePreferencesVisibleController";
		case AudioStreamerCreateStreamOptions:
			return @"AudioStreamerCreateStreamOptions2";
		case AudioStreamerAutoLock:
			return @"auto_lock_in_dock";
		case AudioStreamerPlayerInterrupted:
			return @"AudioStreamerPlayerInterrupted";

		default:
			return @"";
	}
}

@end
