//
//  PlayerEventNotifications.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/24/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DAY_IN_SECONDS 86400
#define WEEK_IN_SECONDS 604800

typedef enum
{
	AudioStreamerFetchMissedSongs = 0,
	AudioStreamerTopSongsAreFresh,
	AudioStreamerTopSongsLastFetchDate,
	AudioStreamerTopSongsStationTimestamp,
	AudioStreamerLastVoteCleanupDate,
	AudioStreamerLastCleanupDate,
	AudioStreamerStationCreatedKey,
	AudioStreamerRecentsIndex,
	AudioStreamerHTMLAbout,
	AudioStreamerHTMLSupport,
	AudioStreamerMoreDetail,
	AudioStreamerPlayState,
	StartupRestoreStationIndexKey,
	StartupRestoreNavigationStack,
	StartupRestoreScrollPage,
	StartupRestorePreferencesScrollFrame,
	StartupRestoreTabIndex,
	StartupRestoreTableVisibleRange,
	StartupRestoreMailPickerChosen,
	StartupRestoreHTMLViewChosen,
	StartupRestoreSongTableSelectedRow,
	StartupRestoreShowingPreferences,
	StartupRestorePreferencesVisibleController,
	StartupRestoreDetailSongID,
	AudioStreamerCreateStreamOptions,
	AudioStreamerAutoLock,
	AudioStreamerPlayerInterrupted
} AudioStreamerStatusRecoveryTypes;

typedef enum
{
	songVoteRecordedUnknown = 0,
	songVoteRecordedYes = 1,
	songVoteRecordedNo = 2,
	songVoteRecordedPending = 3 // to indicate that the vote/rating was JUST saved...
} SongVoteRecordedIndicator;

@interface PlayerEventNotifications : NSObject {

}

+ (NSString *) keyForStatus: (AudioStreamerStatusRecoveryTypes) status;
@end
