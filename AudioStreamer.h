//
//  AudioStreamer.h
//  MusicOne
//
//  Created by Bobby Wallace on 01/26/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//
//  Some code created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//


#import <UIKit/UIKit.h>
#include <pthread.h>
#include <AudioToolbox/AudioToolbox.h>
#import "MusicPlayerAppDelegate.h"
#import "StreamOption.h"

#define REQUEST_TIMEOUT 240.0

#define LOG_QUEUED_BUFFERS 0

#define DEBUG_SCREEN 0

//#define kNumAQRetryAttempts 3;

#define kNumAQBufs 16			// Number of audio queue buffers we allocate.
// Needs to be big enough to keep audio pipeline
// busy (non-zero number of queued buffers) but
// not so big that audio takes too long to begin
// (kNumAQBufs * kAQBufSize of data must be
// loaded before playback will start).
// Set LOG_QUEUED_BUFFERS to 1 to log how many
// buffers are queued at any time -- if it drops
// to zero too often, this value may need to
// increase. Min 3, typical 8-24.

#define kAQBufSize 2048			// Number of bytes in each audio queue buffer
// Needs to be big enough to hold a packet of
// audio from the audio file. If number is too
// large, queuing of audio before playback starts
// will take too long.
// Highly compressed files can use smaller
// numbers (512 or less). 2048 should hold all
// but the largest packets. A buffer size error
// will occur if this number is too small.

#define kAQMaxPacketDescs 512	// Number of packet descriptions in our array

typedef enum
{
	AS_INITIALIZED = 0,
	AS_STARTING_FILE_THREAD,
	AS_WAITING_FOR_DATA,
	AS_WAITING_FOR_QUEUE_TO_START,
	AS_PLAYING,
	AS_BUFFERING,
	AS_STOPPING,
	AS_STOPPED,
	AS_PAUSED,
	AS_ERROR_RETRY,
	AS_GETPLAYLIST,
	AS_STREAMER_STARTING
} AudioStreamerState;

typedef enum
{
	AS_NO_STOP = 0,
	AS_STOPPING_EOF,
	AS_STOPPING_USER_ACTION,
	AS_STOPPING_AUDIO_ROUTE_CHANGE,
	AS_STOPPING_USER_RESTART,
	AS_URLTIMEOUT_ERROR,
	AS_URLHOST_ERROR,
	AS_STREAM_ENDED_ERROR,
	AS_NOTREACHABLE_ERROR,
	AS_STOPPING_ERROR,
	AS_STOPPING_TEMPORARILY
} AudioStreamerStopReason;

typedef enum
{
	AS_NO_ERROR = 0,
	AS_NETWORK_CONNECTION_FAILED,
	AS_FILE_STREAM_GET_PROPERTY_FAILED,
	AS_FILE_STREAM_SEEK_FAILED,
	AS_FILE_STREAM_PARSE_BYTES_FAILED,
	AS_FILE_STREAM_OPEN_FAILED,
	AS_FILE_STREAM_HOST_UNREACHABLE,
	AS_FILE_STREAM_CLOSE_FAILED,
	AS_AUDIO_DATA_NOT_FOUND,
	AS_AUDIO_DATA_CONNECTION_TIMEOUT,
	AS_AUDIO_DATA_CONNECTION_ERROR,
	AS_AUDIO_DATA_CONNECTION_STREAM_ENDED,
	AS_AUDIO_QUEUE_CREATION_FAILED,
	AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED,
	AS_AUDIO_QUEUE_ENQUEUE_FAILED,
	AS_AUDIO_QUEUE_ADD_LISTENER_FAILED,
	AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED,
	AS_AUDIO_QUEUE_START_FAILED,
	AS_AUDIO_QUEUE_PAUSE_FAILED,
	AS_AUDIO_QUEUE_BUFFER_MISMATCH,
	AS_AUDIO_QUEUE_DISPOSE_FAILED,
	AS_AUDIO_QUEUE_STOP_FAILED,
	AS_AUDIO_QUEUE_FLUSH_FAILED,
	AS_AUDIO_STREAMER_FAILED,
	AS_GET_AUDIO_TIME_FAILED,
	AS_AUDIO_BUFFER_TOO_SMALL,
	AS_REQUEST_OPEN_FAILED,
	AS_URL_OPEN_FAILED,
	AS_URL_NO_PLAYLIST,
	AS_URL_TRY_NEXT,
	AS_INCORRECT_SERVER_RESPONSE
} AudioStreamerErrorCode;

@protocol AudioStreamerErrorHandlerDelegate;

@protocol AudioStreamerErrorHandlerDelegate
- (void)handleStreamerError:(NSError *)error;
- (void) startNetworkActivity;
- (void) stopNetworkActivity;

@optional
- (void)performSelectorOnMainThread:(SEL) selector withObject:(id)object waitUntilDone:(BOOL) wait;
- (void)performSelector:(SEL) selector onThread:(NSThread *) thread withObject:(id)object waitUntilDone:(BOOL) wait;

@end

@interface AudioStreamer : NSObject{
	//
	// Special threading consideration:
	//	The audioQueue property should only ever be accessed inside a
	//	synchronized(self) block and only *after* checking that ![self isFinishing]
	//
	AudioFileStreamID audioFileStream;	// the audio file stream parser
	AudioQueueRef audioQueue;

	size_t bytesFilled;				// how many bytes have been filled
	size_t packetsFilled;			// how many packets have been filled
	bool inuse[kNumAQBufs];			// flags to indicate that a buffer is still in use
	AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];		// audio queue buffers
	NSInteger buffersUsed;
#if DEBUG_SCREEN
	NSInteger bufferCount;
#endif
	unsigned int fillBufferIndex;	// the index of the audioQueueBuffer that is being filled

	AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio

	AudioStreamerState state;
	NSString *track, *streamTitle;
	
	AudioStreamerStopReason stopReason;
	AudioStreamerErrorCode errorCode;
	OSStatus status;
	
	bool discontinuous;			// flag to indicate middle of the stream
	
	pthread_mutex_t queueBuffersMutex;			// a mutex to protect the inuse flags
	pthread_cond_t queueBufferReadyCondition;	// a condition varable for handling the inuse flags
	
	StreamOption *theStreamOption;
	NSURLConnection *url;
	NSMutableURLRequest *theRequest;
	NSMutableData *audioData;
	NSData * icyHeader;
	BOOL processAsIcy;
	BOOL isAnyAudioSubmitted;
	
	BOOL readHeader;

	//NSRunLoop * curRunLoop;

	UInt32 bitRate;
	NSUInteger dataOffset;
	UInt32 dataFormat;
	NSString *bitRateString;
	
	bool seekNeeded;
	double seekTime;
	double sampleRate;
	double lastProgress;
	
	NSInteger audioBytesRead, audioBytesInData;
	NSInteger icyMetaDataInterval;
	NSInteger lengthOfMetaTitle;

	NSInteger currentUrlIndex;

	NSMutableDictionary *urlLists;

	id<AudioStreamerErrorHandlerDelegate> errorHandlerDelegate;
	
	MusicPlayerAppDelegate * appDelegate;

	NSTimer * gainTimer;
}

@property (nonatomic, assign) NSURLConnection * url;

#if DEBUG_SCREEN
@property (assign) NSInteger bufferCount;
#endif
@property (nonatomic, retain) StreamOption *theStreamOption;
@property (nonatomic, retain) NSMutableData *audioData;
//@property (nonatomic) NSInteger icyMetaDataInterval;
@property BOOL processAsIcy;
@property (readonly) AudioStreamerState state;
@property AudioStreamerErrorCode errorCode;
@property AudioStreamerStopReason stopReason;
@property (readonly) double progress;
@property (readwrite) UInt32 bitRate;
@property (readwrite) NSInteger currentUrlIndex;
@property (nonatomic, copy) NSString *track, *streamTitle;
@property (nonatomic, assign) UInt32 dataFormat;
@property (nonatomic, retain) NSString *bitRateString;
@property (assign) id<AudioStreamerErrorHandlerDelegate> errorHandlerDelegate;

+ (NSString *)stringForErrorCode:(AudioStreamerErrorCode)anErrorCode;
+ (NSString *) audioSessionStatusCodeStr:(UInt32) statusCode;
+ (NSString *) stringForState:(AudioStreamerState) streamerState;
+ (NSString *) stringForStopReason:(AudioStreamerStopReason) stopCode;
+ (NSString *) stringForFormatID:(UInt32) dataFormat;
+ (NSString *) translateAudioFileStreamProperties:(UInt32)audioFileStreamProperty;

- (id) initWithStation: (StreamOption *)station;
- (void)start;
- (void)stop;
- (void)stop: (BOOL) immediate reason:(AudioStreamerStopReason) reason;
- (void)pause;
- (BOOL)isPlaying;
- (BOOL)isPaused;
- (BOOL)isWaiting;
- (BOOL)isIdle;
- (BOOL)isStopped;


@end
