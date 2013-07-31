//
//  AudioStreamer.m
//  MusicOne
//
//  Created by Bobby Wallace on 01/26/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//
//  Some code adpated by code created by Matt Gallagher on 28/10/08.
//  Copyright Matt Gallagher 2008. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "AudioStreamer.h"
#import "MusicPlayerAppDelegate.h"
#import "MusicPlayerController.h"

@interface AudioStreamer ()
@property (readwrite) AudioStreamerState state;

- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
					 fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
								  ioFlags:(UInt32 *)ioFlags;
- (void)handleAudioPackets:(const void *)inInputData
			   numberBytes:(UInt32)inNumberBytes
			 numberPackets:(UInt32)inNumberPackets
		packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;
- (void)handleBufferCompleteForQueue:(AudioQueueRef)inAQ
							  buffer:(AudioQueueBufferRef)inBuffer;
- (void)handlePropertyChangeForQueue:(AudioQueueRef)inAQ
						  propertyID:(AudioQueuePropertyID)inID;
- (void)enqueueBuffer;
- (NSString *) getCurrentUrlString;
- (NSUInteger)indexOfData:(NSString*)needle inData:(NSData*)haystack encoding:(NSStringEncoding) encoding;
- (NSData *)getIcyParmValueS:(NSString *)icyParmName inData:(NSData*)haystack;
- (void) correctLengthOverflow: (NSData *) data range: (NSRange *)range;
- (void)failWithErrorCode:(AudioStreamerErrorCode)anErrorCode;
- (void)failWithErrorCode:(AudioStreamerErrorCode)anErrorCode withError:(NSError *) error retry: (BOOL) retry;

- (void)startInternal;
//- (void)startInternalCore;
- (BOOL)runLoopShouldExit;

@end

#pragma mark -
#pragma mark AudioFileStream Callback Function Prototypes
void MyPropertyListenerProc(	void *							inClientData,
							AudioFileStreamID				inAudioFileStream,
							AudioFileStreamPropertyID		inPropertyID,
							UInt32 *						ioFlags);
void MyPacketsProc(				void *							inClientData,
				   UInt32							inNumberBytes,
				   UInt32							inNumberPackets,
				   const void *					inInputData,
				   AudioStreamPacketDescription	*inPacketDescriptions);

#pragma mark -
#pragma mark AudioQueue Callback Function Prototypes

void MyAudioQueueOutputCallback(void* inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

#pragma mark -
#pragma mark AudioFileStream Callback Function Implementations

//
// MyPropertyListenerProc
//
// Receives notification when the AudioFileStream has audio packets to be
// played. In response, this function creates the AudioQueue, getting it
// ready to begin playback (playback won't begin until audio packets are
// sent to the queue in MyEnqueueBuffer).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// kAudioQueueProperty_IsRunning listening added.
//
void MyPropertyListenerProc(	void *							inClientData,
							AudioFileStreamID				inAudioFileStream,
							AudioFileStreamPropertyID		inPropertyID,
							UInt32 *						ioFlags)
{	
	// this is called by audio file stream when it finds property values
	AudioStreamer* streamer = (AudioStreamer *)inClientData;
	[streamer
	 handlePropertyChangeForFileStream:inAudioFileStream
	 fileStreamPropertyID:inPropertyID
	 ioFlags:ioFlags];
}

//
// MyPacketsProc
//
// When the AudioStream has packets to be played, this function gets an
// idle audio buffer and copies the audio packets into it. The calls to
// MyEnqueueBuffer won't return until there are buffers available (or the
// playback has been stopped).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
void MyPacketsProc(				void *							inClientData,
				   UInt32							inNumberBytes,
				   UInt32							inNumberPackets,
				   const void *					inInputData,
				   AudioStreamPacketDescription	*inPacketDescriptions)
{
	// this is called by audio file stream when it finds packets of audio
	AudioStreamer* streamer = (AudioStreamer *)inClientData;
	[streamer
	 handleAudioPackets:inInputData
	 numberBytes:inNumberBytes
	 numberPackets:inNumberPackets
	 packetDescriptions:inPacketDescriptions];
}

#pragma mark -
#pragma mark AudioQueue Callback Function Implementations

//
// MyAudioQueueOutputCallback
//
// Called from the AudioQueue when playback of specific buffers completes. This
// function signals from the AudioQueue thread to the AudioStream thread that
// the buffer is idle and available for copying data.
//
// This function is unchanged from Apple's example in AudioFileStreamExample.
//
void MyAudioQueueOutputCallback(	void*					inClientData, 
								AudioQueueRef			inAQ, 
								AudioQueueBufferRef		inBuffer)
{
	// this is called by the audio queue when it has finished decoding our data. 
	// The buffer is now free to be reused.
	AudioStreamer* streamer = (AudioStreamer*)inClientData;
	[streamer handleBufferCompleteForQueue:inAQ buffer:inBuffer];
}

//
// MyAudioQueueIsRunningCallback
//
// Called from the AudioQueue when playback is started or stopped. This
// information is used to toggle the observable "isPlaying" property and
// set the "finished" flag.
//
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	AudioStreamer* streamer = (AudioStreamer *)inUserData;
	[streamer handlePropertyChangeForQueue:inAQ propertyID:inID];
}

#pragma mark -

@implementation AudioStreamer

#if DEBUG_SCREEN
@synthesize bufferCount;
#endif

@synthesize theStreamOption;
//@synthesize icyMetaDataInterval;
@synthesize processAsIcy;
@synthesize audioData;
@synthesize state;
@synthesize errorCode;
@synthesize stopReason;
@synthesize bitRate;
@synthesize track, streamTitle;
@synthesize currentUrlIndex;
@synthesize dataFormat;
@synthesize bitRateString;
@synthesize errorHandlerDelegate;

@synthesize url;

@dynamic progress;

- (id) initWithStation: (StreamOption *)station {
	self = [super init];
	if (self != nil)
	{
		theStreamOption = station;
		audioData=[[NSMutableData data] retain];
		if(audioData == nil)
			return nil;
		
		appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		self.bitRateString = [NSString string];
		self.dataFormat = 0;
		self.track = [NSString string];
	}
		
	return self;
	
}

- (void) dealloc {
	// [self stop];
	
	//NSLog(@"Dealloc streamer");
	[audioData release];
	
	[super dealloc];
}

+ (NSString *) audioSessionStatusCodeStr:(UInt32) statusCode {
	
	NSString * val;
	switch (statusCode) {
		case kAudioSessionNoError:
			val = @"kAudioSessionNoError";
			break;
		case kAudioSessionNotInitialized:
			val = @"kAudioSessionNotInitialized";
			break;
		case kAudioSessionAlreadyInitialized:
			val = @"kAudioSessionAlreadyInitialized";
			break;
		case kAudioSessionInitializationError:
			val = @"kAudioSessionInitializationError";
			break;
		case kAudioSessionUnsupportedPropertyError:
			val = @"kAudioSessionUnsupportedPropertyError";
			break;
		case kAudioSessionBadPropertySizeError:
			val = @"kAudioSessionBadPropertySizeError";
			break;
		case kAudioSessionNotActiveError:
			val = @"kAudioSessionNotActiveError";
			break;
		case kAudioServicesNoHardwareError:
			val = @"kAudioServicesNoHardwareError";
			break;
		case kAudioSessionNoCategorySet:
			val = @"kAudioSessionNoCategorySet";
			break;
		case kAudioSessionIncompatibleCategory:
			val = @"kAudioSessionIncompatibleCategory";
			break;
		default:
			val=@"unknown code";
	} 
	return val;
}

//
// failWithErrorCode:
//
// Sets the playback state to failed and logs the error.
//
// Parameters:
//    anErrorCode - the error condition
//
- (void)failWithErrorCode:(AudioStreamerErrorCode)anErrorCode
{
	[self failWithErrorCode:anErrorCode withError:nil retry:NO];
}

- (void)failWithErrorCode:(AudioStreamerErrorCode)anErrorCode withError:(NSError *) error retry: (BOOL) retry
{
	
	@synchronized(self)
	{
		if (errorCode != AS_NO_ERROR)
		{
			// Only set the error once.
			return;
		}
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		errorCode = anErrorCode;
		
		if (status)
		{
			char *errChars = (char *)&status;
			NSLog(@"%@ / %@ err: %c%c%c%c %d\n",
				  [AudioStreamer stringForErrorCode:anErrorCode],
				  [AudioStreamer audioSessionStatusCodeStr:status],
				  errChars[3], errChars[2], errChars[1], errChars[0],
				  (int)status);
		}
		else
		{
			NSLog(@"%@", [AudioStreamer stringForErrorCode:anErrorCode]);
		}
		
		if (state == AS_PLAYING ||
			state == AS_PAUSED ||
			state == AS_BUFFERING)
		{
			self.state = AS_STOPPING;
			self.stopReason = AS_STOPPING_ERROR;
			AudioQueueStop(audioQueue, true);
		}
		
		NSString * errorCodeString = [AudioStreamer stringForErrorCode:self.errorCode];
		
		NSMutableDictionary *userInfo;
		NSInteger code;
		if(error != nil) {
			userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
			code = [error code];
		} else {
			userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:errorCodeString forKey:NSLocalizedDescriptionKey];
			code = self.errorCode;
		}
		
		[userInfo setObject:[NSNumber numberWithBool:retry] forKey:NSUnderlyingErrorKey];
		[userInfo setObject:errorCodeString forKey:NSStringEncodingErrorKey];
		
		NSError *err = [NSError errorWithDomain:@"com.bikeath1337.streamer.ErrorDomain" code:code userInfo:userInfo];
		
		[self.errorHandlerDelegate performSelectorOnMainThread:@selector(handleStreamerError:) withObject:err waitUntilDone:NO];
		
		[pool drain];
	}
}

//
// isFinishing
//
// returns YES if the audio has reached a stopping condition.
//
- (BOOL)isFinishing {
	@synchronized (self)
	{
		if ((errorCode != AS_NO_ERROR && state != AS_INITIALIZED) ||
			((state == AS_STOPPING || state == AS_STOPPED) &&
			 stopReason != AS_STOPPING_TEMPORARILY))
		{
			return YES;
		}
	}
	
	return NO;
}

//
// isPlaying
//
// returns YES if the audio currently playing.
//
- (BOOL)isPlaying {
	return state == AS_PLAYING;
}

//
// isPaused
//
// returns YES if the audio currently playing.
//
- (BOOL)isPaused
{
	return state == AS_PAUSED;
}

//
// isWaiting
//
// returns YES if the AudioStreamer is waiting for a state transition of some
// kind.
//
- (BOOL)isWaiting {
	@synchronized(self)
	{
		if ([self isFinishing] ||
			state == AS_STARTING_FILE_THREAD||
			state == AS_WAITING_FOR_DATA ||
			state == AS_WAITING_FOR_QUEUE_TO_START ||
			state == AS_BUFFERING)
		{
			return YES;
		}
	}
	
	return NO;
}

//
// isIdle
//
// returns YES if the AudioStream is in the AS_INITIALIZED state (i.e.
// isn't doing anything).
//
- (BOOL)isIdle {
	return state == AS_INITIALIZED;
}

//
// isStopped
//
// returns YES if the AudioStream is in the AS_STOPPED state (i.e.
// isn't doing anything).
//
- (BOOL)isStopped {
	return state == AS_STOPPED;
}

- (NSString *) getCurrentUrlString 
{

	if(self.theStreamOption.playlistUrl == nil){
		if (self.currentUrlIndex == 0) {
			return nil;
		}
		currentUrlIndex=0;
		return self.theStreamOption.urlString;
	}
	if (self.currentUrlIndex == [[appDelegate getUrls] count] ) {
		return nil;
	}
	
	self.currentUrlIndex += 1;
	
	return [[appDelegate getUrls] objectAtIndex:self.currentUrlIndex];
}

//
// openFileStream
//
// Open the audioFileStream to parse data and the fileHandle as the data
// source.
//
- (BOOL)openFileStream
{
	@synchronized(self)
	{

		do {
			
			if (audioFileStream)
			{
				AudioFileStreamClose(audioFileStream);
				audioFileStream = nil;
			}
			
			// Create the stream parser
			status = AudioFileStreamOpen(self, MyPropertyListenerProc, MyPacketsProc, 
										 [self.theStreamOption.streamType intValue], &audioFileStream);
			
			if (status)
			{
				[self failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
				break;
			}
			
			//
			// Create the GET URL request, if it is not created
			//
			NSString *urlString = [self getCurrentUrlString];
			
			//urlString = [urlString stringByAppendingString:@"xxxx"];
			//urlString = @"http://localhost:8080/";
			//NSLog(@"opening request: %@", urlString);
			theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
											   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										   timeoutInterval:REQUEST_TIMEOUT];
			
			if (theRequest == nil)
			{
				[self failWithErrorCode:AS_REQUEST_OPEN_FAILED];
				break;
			}
			
			[theRequest setValue:self.theStreamOption.contentType forHTTPHeaderField:@"content-type"];
			
			if(self.theStreamOption.icyMetaTitleCompliant)
				[theRequest setValue:@"1" forHTTPHeaderField:@"Icy-MetaData"];
			
			//
			// Handle SSL connections
			//
			if( [[[theRequest URL] absoluteString] rangeOfString:@"https"].location != NSNotFound )
			{
				UIAlertView *alert =
				[[UIAlertView alloc]
				 initWithTitle:NSLocalizedStringFromTable(@"HTTPSError", @"Errors", nil)
				 message:NSLocalizedStringFromTable(@"NoHTTPSSupport", @"Errors", nil)
				 delegate:self
				 cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Buttons", nil)
				 otherButtonTitles: nil];
				[alert
				 performSelector:@selector(show)
				 onThread:[NSThread mainThread]
				 withObject:nil
				 waitUntilDone:YES];
				[alert release];
			}
			
			//
			// Open the URL connection
			//
			
			NSAssert(![[NSThread currentThread] isEqual:[NSThread mainThread]],
					 @"openFileStream cannot be done on the main thread.");
			NSAssert(![[NSRunLoop currentRunLoop] isEqual:[NSRunLoop mainRunLoop]],
					 @"openFileStream cannot be done on the main run loop.");

			url = [NSURLConnection connectionWithRequest:theRequest delegate:self];
			if (url == nil)
			{
				[self failWithErrorCode:AS_URL_OPEN_FAILED];
				break;
			}
			
			[audioData setLength:0];
			[url scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

			return YES;

		} while (NO);

	} 
	
	return NO;
}

//
// startInternal
//
// This is the start method for the AudioStream thread. This thread is created
// because it will be blocked when there are no audio buffers idle (and ready
// to receive audio data).
//
// Activity in this thread:
//	- Creation and cleanup of all AudioFileStream and AudioQueue objects
//	- Receives data from the CFReadStream
//	- AudioFileStream processing
//	- Copying of data from AudioFileStream into audio buffers
//  - Stopping of the thread because of end-of-file
//	- Stopping due to error or failure
//
// Activity *not* in this thread:
//	- AudioQueue playback and notifications (happens in AudioQueue thread)
//  - Actual download of NSURLConnection data (NSURLConnection's thread)
//	- Creation of the AudioStreamer (other, likely "main" thread)
//	- Invocation of -start method (other, likely "main" thread)
//	- User/manual invocation of -stop (other, likely "main" thread)
//
// This method contains bits of the "main" function from Apple's example in
// AudioFileStreamExample.
//
- (void)startInternal
{
		
	@synchronized(self)
	{
		if (state != AS_STARTING_FILE_THREAD)
		{
			if (state != AS_STOPPING &&
				state != AS_STOPPED)
			{
				NSLog(@"### Not starting audio thread. State code is: %ld", state);
			}
			
			self.state = AS_INITIALIZED;

			return;
		}

		// initialize a mutex and condition so that we can block on buffers in use.
		pthread_mutex_init(&queueBuffersMutex, NULL);
		pthread_cond_init(&queueBufferReadyCondition, NULL);
		
	}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	self.state = AS_GETPLAYLIST;

	NSUInteger maxUrls = [[appDelegate getUrls] count];
	NSUInteger i=0;

	self.state = AS_WAITING_FOR_DATA;

	for (i=0; i<maxUrls; i++) {

		errorCode = AS_NO_ERROR;

		url = nil;
		if ([self openFileStream])
		{
			//
			// Process the run loop until playback finishes or fails.
			//
			BOOL isRunning = YES;
			do
			{

				isRunning = [[NSRunLoop currentRunLoop]
							 runMode:NSDefaultRunLoopMode
							 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];

				//
				// If there are no queued buffers, we need to check here since the
				// handleBufferCompleteForQueue:buffer: should not change the state
				// (may not enter the synchronized section).
				//
				if (buffersUsed == 0 && self.state == AS_PLAYING )
				{
					status = AudioQueuePause(audioQueue);
					if (status)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_PAUSE_FAILED];
						return;
					}

					self.state = AS_BUFFERING;
					
//					if([errorHandlerDelegate reachable]) {
//						[errorHandlerDelegate queueRestart];
//					}
				}
				
			} while (isRunning && ![self runLoopShouldExit]);
		} else {
			NSLog(@"Failed open filestream");
		}

		@synchronized(self)
		{

			//
			// Cleanup the read stream if it is still open
			//
			if (url)
			{
				[url cancel];
			}
			
			//
			// Close the audio file stream,
			//
			if (audioFileStream)
			{
				AudioFileStreamClose(audioFileStream);
				audioFileStream = nil;
			}
			
			//
			// Dispose of the Audio Queue
			//
			if (audioQueue)
			{
				AudioQueueDispose(audioQueue, NO);
				audioQueue = nil;
			}
			
			bytesFilled = 0;
			packetsFilled = 0;
			seekTime = 0;
			seekNeeded = NO;
#if DEBUG_SCREEN
			self.bufferCount = 0;
#endif
			self.state = AS_INITIALIZED;
			
		}
		
		
		if(errorCode == AS_URL_TRY_NEXT){
			NSLog(@"Bad url");
			errorCode = AS_NO_ERROR;
		} else {
			break;
		}

	}

	@synchronized(self) {
		
		pthread_mutex_destroy(&queueBuffersMutex);
		pthread_cond_destroy(&queueBufferReadyCondition);

	}

	if(i==maxUrls){
		
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
		[userInfo setObject:NSLocalizedStringFromTable(@"NoMoreURLOptions", @"Errors", nil) forKey:NSLocalizedDescriptionKey];
		[userInfo setObject:NSLocalizedStringFromTable(@"NoValidAudioStream", @"Errors", nil) forKey:NSLocalizedFailureReasonErrorKey];
		[userInfo setObject:NSLocalizedStringFromTable(@"TryAgainLater", @"Errors", nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
		NSError *err = [NSError errorWithDomain:@"com.bikeath1337.streamer.ErrorDomain" code:AS_URL_TRY_NEXT userInfo:userInfo];

		[self failWithErrorCode:AS_URL_OPEN_FAILED withError:err retry:NO];
	}
	
	[pool release];

}

//
// runLoopShouldExit
//
// returns YES if the run loop should exit.
//
- (BOOL)runLoopShouldExit {
	@synchronized(self)
	{
		if (errorCode != AS_NO_ERROR ||
			(state == AS_STOPPED &&
			 stopReason != AS_STOPPING_TEMPORARILY))
		{
			//NSLog(@"Errorcode=%d", errorCode);
			return YES;
		}
	}
	
	return NO;
}

//
// start
//
// Calls startInternal in a new thread.
//
- (void)start
{
	@synchronized (self)
	{

		if (state == AS_PAUSED)
		{
			[self pause];
		}
		else if (state == AS_INITIALIZED)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

			//	NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
			//		 @"Playback can only be started from the main thread.");
			
			NSUInteger maxUrls = [[appDelegate getUrls] count];
			
			if (maxUrls == 0) {
				NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
				[userInfo setObject:NSLocalizedStringFromTable(@"HostNotReachable", @"Errors", nil) forKey:NSLocalizedDescriptionKey];
				NSError *err = [NSError errorWithDomain:@"com.bikeath1337.streamer.ErrorDomain" code:AS_FILE_STREAM_HOST_UNREACHABLE userInfo:userInfo];
				
				[self failWithErrorCode:AS_URL_NO_PLAYLIST withError:err retry:NO];

				[pool drain];
				return;
			}
			
			self.currentUrlIndex = -1;

			self.state = AS_STARTING_FILE_THREAD;
			
			if ([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
				[NSThread
				 detachNewThreadSelector:@selector(startInternal)
				 toTarget:self
				 withObject:nil];
			} else {
				[self performSelectorInBackground:@selector(startInternal) withObject:nil];
			}
			
			[pool drain];
		}
	}
}

//
// pause
//
// A togglable pause function.
//
- (void)pause
{
	@synchronized(self)
	{
		if (state == AS_PLAYING)
		{
			
			status = AudioQueuePause(audioQueue);
			if (status)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_PAUSE_FAILED];
				return;
			}
			self.state = AS_PAUSED;
		}
		else if (state == AS_PAUSED)
		{

			status = AudioQueueStart(audioQueue, NULL);
			if (status)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
				return;
			}
			self.state = AS_PLAYING;

			AudioQueueSetParameter (audioQueue, kAudioQueueParam_Volume, 0.0 );
			
			[self performSelectorOnMainThread:@selector(fadeIn) withObject:nil waitUntilDone:NO];
		}
	}
}

//
// stop
//
// This method can be called to stop downloading/playback before it completes.
// It is automatically called when an error occurs.
//
// If playback has not started before this method is called, it will toggle the
// "isPlaying" property so that it is guaranteed to transition to true and
// back to false 
//
- (void)stop
{
	[self stop:YES reason:AS_STOPPING_USER_ACTION];
	
}

- (void)stop:(BOOL) immediate reason:(AudioStreamerStopReason) reason
{
	
	@synchronized(self)
	{

		if (state == AS_PLAYING || state == AS_PAUSED ||
			 state == AS_BUFFERING || state == AS_WAITING_FOR_QUEUE_TO_START ||
			 state == AS_WAITING_FOR_DATA)
		{
			self.state = AS_STOPPING;
			self.stopReason = reason;
			
			if(audioQueue) AudioQueueStop(audioQueue, immediate);
			
		}
		else if (state != AS_INITIALIZED && state != AS_STOPPED)
		{
			self.state = AS_STOPPED;
			self.stopReason = reason;
			
		} else {

			self.stopReason = reason;
			
		}
		
	}
}


//
// progress
//
// returns the current playback progress. Will return zero if sampleRate has
// not yet been detected.
//
- (double)progress
{
	@synchronized(self)
	{
		if (sampleRate > 0 && ![self isFinishing])
		{

			if (state != AS_PLAYING && state != AS_PAUSED && state != AS_BUFFERING)
			{

				return lastProgress;
			}
			
			AudioTimeStamp queueTime;
			Boolean discontinuity;
			status = AudioQueueGetCurrentTime(audioQueue, NULL, &queueTime, &discontinuity);
			if (status)
			{
				NSLog(@"AudioQueueGetCurrentTime failed -- continuing");
			}
			
			double progress = seekTime + queueTime.mSampleTime / sampleRate;
			if (progress < 0.0)
			{
				progress = 0.0;
			}
			
			lastProgress = progress;

			return progress;
		}
	}
	
	return lastProgress;
}

//
// shouldSeek
//
// Applies the logic to verify if seeking should occur.
//
// returns YES (seeking should occur) or NO (otherwise).
//
- (BOOL)shouldSeek
{
	@synchronized(self)
	{
		if (bitRate != 0 && bitRate != ~0 && seekNeeded &&
			(state == AS_PLAYING || state == AS_PAUSED || state == AS_BUFFERING))
		{
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	// Allow redirection
//	NSLog(@"redirection request to:=%@", [[request mainDocumentURL] absoluteString]);
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(lostInternetConnection) object:nil];

	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}

		if(self.theStreamOption.icyMetaTitleCompliant) {
			self.processAsIcy = YES;
			readHeader = YES;
		}
		
		icyMetaDataInterval = -1;
		lengthOfMetaTitle = -1;
		
	}

}

- (void) correctLengthOverflow: (NSData *) data range: (NSRange *)range {
	NSInteger overflow = [data length] - range->location - range->length;
	if (overflow < 0) {
		range->length = [data length] - range->location;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}

		if (NO && self.currentUrlIndex == 0) {
			[self connectionDidFinishLoading:connection];
			return;
		}
	}
	
	NSInteger len = 0;
	len = [data length];
	
	if(len==0) {
		NSLog(@"no buffer!");
		return;
	}

	NSUInteger audioFileStreamParseFlag = (discontinuous) ? kAudioFileStreamParseFlag_Discontinuity : 0;

	if(!self.processAsIcy) {
		// Just pass bytes directly with no further processing and let the Audio Queue Services handle it

		status = AudioFileStreamParseBytes(audioFileStream, [data length], [data bytes], audioFileStreamParseFlag);
		if (status)
		{
			[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
		}
		return;
	}

	NSRange sendRange;
	
	if(readHeader) {
		// don't go beyond
		
		sendRange = (NSRange) {0, icyMetaDataInterval};
		NSRange icyHeaderRange;
		
		NSUInteger endOfIcyHeader = [self indexOfData:@"\r\n\r\n" inData:data encoding:NSASCIIStringEncoding];
		
		if (endOfIcyHeader == NSNotFound) {
			// No icy header found
			self.processAsIcy = NO;
			status = AudioFileStreamParseBytes(audioFileStream, [data length], [data bytes], audioFileStreamParseFlag);
			if (status)
			{
				[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
				return;
			}
			
			return;
		} 
		
		// ICY Header Found, now start to process it
			
		icyHeaderRange = (NSRange) {0,endOfIcyHeader + 4}; // Add on 4 bytes for the empty line
		
		NSData *icyHeaderData = [[NSData alloc] initWithData:[data subdataWithRange:icyHeaderRange]];
		
		NSString *asciiHeader = [[NSString alloc] initWithData:icyHeaderData encoding:NSASCIIStringEncoding];
		
		[icyHeaderData release];
		[asciiHeader release];

		NSString *serverResponseCode = [[NSString alloc] initWithData:[data subdataWithRange:(NSRange){0,10}] encoding:NSASCIIStringEncoding];

		if ([self.theStreamOption.serverType intValue] == SS_TYPE_SHOUTCAST && ![serverResponseCode isEqualToString:@"ICY 200 OK"]) {
			[serverResponseCode release];
			[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
			return;
		}
		
		[serverResponseCode release];
		
		NSString * val = [[NSString alloc] initWithData:[self getIcyParmValueS:@"icy-br" inData:data] encoding:NSASCIIStringEncoding];

		self.bitRateString = val;
		[val release];
		
		NSString * intervalString = [[NSString alloc] initWithData:[self getIcyParmValueS:@"icy-metaint" inData:data] encoding:NSASCIIStringEncoding];
		
		if([intervalString integerValue] > 10000 ) {

			icyMetaDataInterval = [intervalString integerValue];
			
		} else { // Just pass bytes directly with no further processing and let the Audio Queue Services handle it
			// Since valid metatlenth information couldn't be found
			[intervalString release];
			
			self.processAsIcy = NO;
			
			status = AudioFileStreamParseBytes(audioFileStream, [data length], [data bytes], audioFileStreamParseFlag);
			if (status)
			{
				[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
				return;
			}
			
			return;
		}
		
		[intervalString release];
		
		isAnyAudioSubmitted = NO;
		readHeader = NO;

		// End of ICY Header Processing
		
		// All data after the parser is audio with intervals of text to indicate
		// the track for "now playing"
				
		// The audio data comprises the rest of the data from the request
		
		sendRange.location =icyHeaderRange.length;
		sendRange.length = [data length] - icyHeaderRange.length;
		
		readHeader = NO;
		
		audioBytesRead = 0;
		lengthOfMetaTitle = 0;
		
	} else {
		// Consider entire data block to be audio data once header has been processed
		sendRange = (NSRange) {0, [data length]};
	}

	NSUInteger audioBytesAvailable;;
	NSUInteger audioIntervalBytesNeeded;;

	// Now Process the Audio bytes
	while (YES) {

		audioBytesAvailable = [data length] - sendRange.location;
		audioIntervalBytesNeeded = icyMetaDataInterval - audioBytesRead;
		
		if(audioIntervalBytesNeeded>0 && audioIntervalBytesNeeded < icyMetaDataInterval) {
			// special case where we didn't get enough audio data on the previous callback
			
			// Do we have enough bytes in data buffer?
			audioIntervalBytesNeeded = (audioIntervalBytesNeeded > audioBytesAvailable) ? audioBytesAvailable : audioIntervalBytesNeeded;
			
			NSRange chunkRange = {sendRange.location, audioIntervalBytesNeeded};

			[self correctLengthOverflow:data range:&chunkRange];
			
			status = AudioFileStreamParseBytes(audioFileStream, chunkRange.length, [[data subdataWithRange:chunkRange] bytes], audioFileStreamParseFlag);
			if (status)
			{
				[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
				return;
			}
			
			audioBytesRead += chunkRange.length;
			
			if ([data length] == chunkRange.location + chunkRange.length) {
				// No more data available in this call
				return;
			}
			
			sendRange.location += chunkRange.length;
			sendRange.length -= chunkRange.length;

			[self correctLengthOverflow:data range:&sendRange];

		}
		
		if (audioBytesRead == icyMetaDataInterval) {
			// try to get metatitle information
			
			NSRange metaTitleRange;

			NSRange sizeByteRange = {sendRange.location,1};
			
			NSString *sizeString = [[NSString alloc] initWithData:[data subdataWithRange:sizeByteRange] encoding:NSASCIIStringEncoding];
			lengthOfMetaTitle = [sizeString characterAtIndex:0];
			lengthOfMetaTitle *= 16; // get actual length by multiplying by 16
			[sizeString release];
			
			// don't include the length byte in the audio data
			sendRange.location++;
			audioBytesAvailable--;
			
			metaTitleRange = (NSRange) {sendRange.location, lengthOfMetaTitle};

			if (lengthOfMetaTitle) {
				
				// skip over any title text as well
				sendRange.location += lengthOfMetaTitle;
				
				[self correctLengthOverflow:data range:&metaTitleRange];

				NSString *nowPlayingMetaData = [[NSString alloc] initWithData:[data subdataWithRange:metaTitleRange] encoding:NSUTF8StringEncoding];
				if (nowPlayingMetaData == nil) {
					nowPlayingMetaData = @"";
				}
				
				//NSLog(@"%@", nowPlayingMetaData);
				
				self.track = self.streamTitle = nowPlayingMetaData;
				
				[nowPlayingMetaData release];
				
			} else {

				if(self.track != @"")
					self.track = @"";
			}
			
			audioBytesRead = 0;
			
			if ([data length] == metaTitleRange.location + metaTitleRange.length) {
				// No more data available in this call
				return;
			}
			
		} 
		
		NSRange chunkRange = {sendRange.location, icyMetaDataInterval};

		[self correctLengthOverflow:data range:&chunkRange];

		status = AudioFileStreamParseBytes(audioFileStream, chunkRange.length, [[data subdataWithRange:chunkRange] bytes], audioFileStreamParseFlag);
		if (status)
		{
			[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
			return;
		}
		
		audioBytesRead += chunkRange.length;
		
		if ([data length] == chunkRange.location + chunkRange.length) {
			// No more data available in this call
			return;
		}
		
		sendRange.location += audioBytesRead;
		sendRange.length -= audioBytesRead;
	}	
	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	NSInteger errCode = [error code];
	NSLog(@"Error %d, %@", errCode, [error localizedDescription]);
	switch (errCode) {
		case -1009: // No Internet Connection
			[self stop:NO reason:AS_NOTREACHABLE_ERROR];
			//			[self failWithErrorCode:AS_AUDIO_DATA_CONNECTION_ERROR withError:error retry:YES];
			return;
		case -1001: // timeout, retry opening the file stream...perhaps there is a connection now
			[self stop:NO reason:AS_URLTIMEOUT_ERROR];
			return;
		case -1003: // host not found, e.g. lost connection
			[self stop:NO reason:AS_URLHOST_ERROR];
			return;
		case -1004: // bad url
			[self stop:YES reason:AS_STOPPING_ERROR];
			return;
		default:
			break;
	}
	
	[self failWithErrorCode:AS_AUDIO_DATA_CONNECTION_ERROR withError:error retry:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// this function should never be called for streaming internet audio 
	// since the stream theoretically lasts forever
	
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
	}
	
	//
	// If there is a partially filled buffer, pass it to the AudioQueue for
	// processing
	//
	if (bytesFilled)
	{
		[self enqueueBuffer];
	}
	
	[self stop:NO reason:AS_STREAM_ENDED_ERROR];
		
}

#pragma mark -
#pragma mark AudioFileStream Callbacks

//
// handleAudioPackets:numberBytes:numberPackets:packetDescriptions:
//
// Object method which handles the implementation of MyPacketsProc
//
// Parameters:
//    inInputData - the packet data
//    inNumberBytes - byte size of the data
//    inNumberPackets - number of packets in the data
//    inPacketDescriptions - packet descriptions
//
- (void)handleAudioPackets:(const void *)inInputData
			   numberBytes:(UInt32)inNumberBytes
			 numberPackets:(UInt32)inNumberPackets
		packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions; 
{
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		if (bitRate == 0)
		{
			UInt32 dataRateDataSize = sizeof(UInt32);
			status = AudioFileStreamGetProperty(
											 audioFileStream,
											 kAudioFileStreamProperty_BitRate,
											 &dataRateDataSize,
											 &bitRate);
			if (status)
			{
				//
				// m4a and a few other formats refuse to parse the bitrate so
				// we need to set an "unparseable" condition here. If you know
				// the bitrate (parsed it another way) you can set it on the
				// class if needed.
				//
				bitRate = ~0;
			}
		}
		
		// we have successfully read the first packests from the audio stream, so
		// clear the "discontinuous" flag
		discontinuous = false;
	}
	
	// the following code assumes we're streaming VBR data. for CBR data, the second branch is used.
	if (inPacketDescriptions)
	{
		for (int i = 0; i < inNumberPackets; ++i)
		{
			SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
			SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
			size_t bufSpaceRemaining;
			
			@synchronized(self)
			{
				// If the audio was terminated before this point, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				if (packetSize > kAQBufSize)
				{
					[self failWithErrorCode:AS_AUDIO_BUFFER_TOO_SMALL];
				}
				
				bufSpaceRemaining = kAQBufSize - bytesFilled;
			}
			
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			if (bufSpaceRemaining < packetSize)
			{
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)inInputData + packetOffset, packetSize);
				
				// fill out packet description
				packetDescs[packetsFilled] = inPacketDescriptions[i];
				packetDescs[packetsFilled].mStartOffset = bytesFilled;
				// keep track of bytes filled and packets filled
				bytesFilled += packetSize;
				packetsFilled += 1;
			}
			
			// if that was the last free packet description, then enqueue the buffer.
			size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
			if (packetsDescsRemaining == 0) {
				[self enqueueBuffer];
			}
		}	
	}
	else // CBR Data
	{
		size_t offset = 0;
		while (inNumberBytes)
		{
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
			if (bufSpaceRemaining < inNumberBytes)
			{
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If we need to seek then unroll the stack back to the
				// appropriate point
				//
				if ([self shouldSeek])
				{
					return;
				}
				
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				bufSpaceRemaining = kAQBufSize - bytesFilled;
				size_t copySize;
				if (bufSpaceRemaining < inNumberBytes)
				{
					copySize = bufSpaceRemaining;
				}
				else
				{
					copySize = inNumberBytes;
				}
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)(inInputData + offset), copySize);
				
				
				// keep track of bytes filled and packets filled
				bytesFilled += copySize;
				packetsFilled = 0;
				inNumberBytes -= copySize;
				offset += copySize;
			}
		}
	}
}

//
// handlePropertyChangeForFileStream:fileStreamPropertyID:ioFlags:
//
// Object method which handles implementation of MyPropertyListenerProc
//
// Parameters:
//    inAudioFileStream - should be the same as self->audioFileStream
//    inPropertyID - the property that changed
//    ioFlags - the ioFlags passed in
//
- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
					 fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
								  ioFlags:(UInt32 *)ioFlags
{
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		switch (inPropertyID) {
			case kAudioFileStreamProperty_ReadyToProducePackets :
			{
				discontinuous = true;
				
				AudioStreamBasicDescription asbd;
				UInt32 asbdSize = sizeof(asbd);
				
				// get the stream format.
				status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
				if (status)
				{
					[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
					return;
				}
				
				OSStatus ignorableError;
				if(asbd.mFormatID == kAudioFormatMPEG4AAC) {
					// Found AAC format, now check to see if the format list is HE or not, if so, use HE
					
					UInt32 formatListSize;
					Boolean writable;
					
					// get list of supported formats
					
					ignorableError = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, &writable);
					if (ignorableError)
					{
						return;
					}
					
					void* formatListData = calloc(1, formatListSize);

					ignorableError = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, formatListData);
					if (ignorableError)
					{
						return;
					}
					
					// Scan through all the supported formats and look for HE AAC
					for (int x = 0; x < formatListSize; x += sizeof(AudioFormatListItem)){
						AudioStreamBasicDescription *pasbd = formatListData + x;
						
						if (pasbd->mFormatID == kAudioFormatMPEG4AAC_HE){
							// HE AAC isn't supported on the simulator for some reason
							if (!TARGET_IPHONE_SIMULATOR){
								
								asbd.mSampleRate = pasbd->mSampleRate;
								asbd.mFormatID = pasbd->mFormatID;
								asbd.mFormatFlags = pasbd->mFormatFlags;
								asbd.mBytesPerPacket = pasbd->mBytesPerPacket;
								asbd.mFramesPerPacket = pasbd->mFramesPerPacket;
								asbd.mBytesPerFrame = pasbd->mBytesPerFrame;
								asbd.mChannelsPerFrame = pasbd->mChannelsPerFrame;
								asbd.mBitsPerChannel = pasbd->mBitsPerChannel;
								asbd.mReserved = pasbd->mReserved;
								
							} else {
								NSLog(@"iPhone Similuator cannot decode AAC-HE. Will play AAC-LC");
							}
							
							break;
						}                                
					}
					free(formatListData);
					
				} else {
					// asbd.mFormatID = [self.theStreamOption.streamType intValue];
				}

				self.dataFormat = asbd.mFormatID;
				sampleRate = asbd.mSampleRate;
				
				// create the audio queue
				status = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, self, NULL, NULL, 0, &audioQueue);
				if (status)
				{
					NSLog(@"Bad fmt=%@", [AudioStreamer stringForFormatID:asbd.mFormatID]);
					self.stopReason = AS_STOPPING_USER_RESTART;
					self.state = AS_STOPPED;
					return;
				}
				
				// start the queue if it has not been started already
				// listen to the "isRunning" property
				status = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, self);
				if (status)
				{
					[self failWithErrorCode:AS_AUDIO_QUEUE_ADD_LISTENER_FAILED];
					return;
				}
				
				// allocate audio queue buffers
				for (unsigned int i = 0; i < kNumAQBufs; ++i)
				{
					status = AudioQueueAllocateBuffer(audioQueue, kAQBufSize, &audioQueueBuffer[i]);
					if (status)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED];
						return;
					}
				}
				
				break;
			}
			case kAudioFileStreamProperty_DataOffset:
			{
				SInt64 offset;
				UInt32 offsetSize = sizeof(offset);
				status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataOffset, &offsetSize, &offset);
				dataOffset = offset;
				if (status)
				{
					[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
					return;
				}
				
				break;
			}
			case kAudioFileStreamProperty_MagicCookieData:
			{
				// get the cookie size
				UInt32 cookieSize;
				Boolean writable;

				OSStatus ignorableError = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
				if (ignorableError)
				{
					return;
				}
				
				// get the cookie data
				void* cookieData = calloc(1, cookieSize);

				ignorableError = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
				if (ignorableError)
				{
					return;
				}
				
				// set the cookie on the queue.

				ignorableError = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
				free(cookieData);
				if (ignorableError)
				{
					return;
				}

				break;
			}
				
		}
	}
}

//
// enqueueBuffer
//
// Called from MyPacketsProc and connectionDidFinishLoading to pass filled audio
// bufffers (filled by MyPacketsProc) to the AudioQueue for playback. This
// function does not return until a buffer is idle for further filling or
// the AudioQueue is stopped.
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
- (void)enqueueBuffer
{
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		inuse[fillBufferIndex] = true;		// set in use flag
		buffersUsed++;

#if DEBUG_SCREEN
		self.bufferCount = buffersUsed;
#endif
		
		// enqueue buffer
		AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
		fillBuf->mAudioDataByteSize = bytesFilled;
		
		if (packetsFilled)
		{
			status = AudioQueueEnqueueBuffer(audioQueue, fillBuf, packetsFilled, packetDescs);
		}
		else
		{
			status = AudioQueueEnqueueBuffer(audioQueue, fillBuf, 0, NULL);
		}
		
		if (status)
		{
			[self failWithErrorCode:AS_AUDIO_QUEUE_ENQUEUE_FAILED];
			return;
		}
		
		
		if (state == AS_BUFFERING ||
			state == AS_WAITING_FOR_DATA ||
			(state == AS_STOPPED && stopReason == AS_STOPPING_TEMPORARILY))
		{
			//
			// Fill all the buffers before starting. This ensures that the
			// AudioFileStream stays a small amount ahead of the AudioQueue to
			// avoid an audio glitch playing streaming files on iPhone SDKs < 3.0
			//
			if (buffersUsed == kNumAQBufs - 1)
			{
				if (self.state == AS_BUFFERING)
				{
					status = AudioQueueStart(audioQueue, NULL);
					if (status)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
						return;
					}
					self.state = AS_PLAYING;
				}
				else
				{
					self.state = AS_WAITING_FOR_QUEUE_TO_START;
					
					
					status = AudioQueueStart(audioQueue, NULL);
					if (status)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
						return;
					}
					
					AudioQueueSetParameter (audioQueue, kAudioQueueParam_Volume, 0.0 );
					
					[self performSelectorOnMainThread:@selector(fadeIn) withObject:nil waitUntilDone:NO];
				}
			}
		}
		
		// go to next buffer
		if (++fillBufferIndex >= kNumAQBufs) fillBufferIndex = 0;
		bytesFilled = 0;		// reset bytes filled
		packetsFilled = 0;		// reset packets filled
	}
	
	// wait until next buffer is not in use
	pthread_mutex_lock(&queueBuffersMutex); 
	while (inuse[fillBufferIndex])
	{
		pthread_cond_wait(&queueBufferReadyCondition, &queueBuffersMutex);
	}
	pthread_mutex_unlock(&queueBuffersMutex);
}

#pragma mark -
#pragma mark AudioQueue Callbacks

//
// handleBufferCompleteForQueue:buffer:
//
// Handles the buffer completetion notification from the audio queue
//
// Parameters:
//    inAQ - the queue
//    inBuffer - the buffer
//
- (void)handleBufferCompleteForQueue:(AudioQueueRef)inAQ
							  buffer:(AudioQueueBufferRef)inBuffer
{
	unsigned int bufIndex = -1;
	for (unsigned int i = 0; i < kNumAQBufs; ++i)
	{
		if (inBuffer == audioQueueBuffer[i])
		{
			bufIndex = i;
			break;
		}
	}
	
	if (bufIndex == -1)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_MISMATCH];
		pthread_mutex_lock(&queueBuffersMutex);
		pthread_cond_signal(&queueBufferReadyCondition);
		pthread_mutex_unlock(&queueBuffersMutex);
		return;
	}
	
	// signal waiting thread that the buffer is free.
	pthread_mutex_lock(&queueBuffersMutex);
	inuse[bufIndex] = false;
	buffersUsed--;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

#if DEBUG_SCREEN
	self.bufferCount = buffersUsed;
#endif

	[pool drain];
	
	//
	//  Enable this logging to measure how many buffers are queued at any time.
	//
#if LOG_QUEUED_BUFFERS
	NSLog(@"Queued buffers: %ld", buffersUsed);
#endif
	
	pthread_cond_signal(&queueBufferReadyCondition);
	pthread_mutex_unlock(&queueBuffersMutex);
}

//
// handlePropertyChangeForQueue:propertyID:
//
// Implementation for MyAudioQueueIsRunningCallback
//
// Parameters:
//    inAQ - the audio queue
//    inID - the property ID
//
- (void)handlePropertyChangeForQueue:(AudioQueueRef)inAQ
						   propertyID:(AudioQueuePropertyID)inID
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@synchronized(self)
	{

		if (inID == kAudioQueueProperty_IsRunning)
		{
			if (state == AS_STOPPING)
			{

				self.state = AS_STOPPED;
				
				[audioData setLength:0];
			}
			else if (state == AS_WAITING_FOR_QUEUE_TO_START)
			{
				//
				// Note about this bug avoidance quirk:
				//
				// On cleanup of the AudioQueue thread, on rare occasions, there would
				// be a crash in CFSetContainsValue as a CFRunLoopObserver was getting
				// removed from the CFRunLoop.
				//
				// After lots of testing, it appeared that the audio thread was
				// attempting to remove CFRunLoop observers from the CFRunLoop after the
				// thread had already deallocated the run loop.
				//
				// By creating an NSRunLoop for the AudioQueue thread, it changes the
				// thread destruction order and seems to avoid this crash bug -- or
				// at least I haven't had it since (nasty hard to reproduce error!)
				//
				[NSRunLoop currentRunLoop];
				
				self.state = AS_PLAYING;
			}
			else
			{
				if (self.state == AS_PLAYING) {
					NSLog(@"AudioQueue requeuing due to a timeout on the input stream.");
				} else {
					// NSLog(@"AudioQueue changed state in unexpected way. State=%d", state);
				}
			}
		}
	}
	
	[pool release];
}

#pragma mark -
#pragma mark Helper Methods

- (void) fadeIn {
	gainTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(gainUp) userInfo:nil repeats:YES];
}

- (void) gainUp {
	@synchronized(self) {
		AudioQueueParameterValue gain;
		AudioQueueGetParameter (audioQueue, kAudioQueueParam_Volume, &gain );
		gain += 0.1;
		if (gain <= 1.01) {
			AudioQueueSetParameter (audioQueue, kAudioQueueParam_Volume, gain );
		} else {
			[gainTimer invalidate];
		}

	}
}

- (NSUInteger)indexOfData:(NSString *)needle inData:(NSData*)haystack encoding:(NSStringEncoding) encoding
{

	NSData *needleData = [needle dataUsingEncoding:encoding];

	NSRange haystackViewport = {0,[needleData length]};
	NSData *haystackSnippet = [haystack subdataWithRange:haystackViewport];
	NSUInteger endOfHaystack = [haystack length] - [needleData length];
	
	BOOL found = NO;
	do {
		if ([needleData isEqualToData:haystackSnippet]){
			return haystackViewport.location;
		}
		
		haystackViewport.location++;
		if (haystackViewport.location >= endOfHaystack) {
			return NSNotFound;
		}
		
		haystackSnippet = [haystack subdataWithRange:haystackViewport];

	} while (YES);

	return (found) ? haystackViewport.location : NSNotFound;
}

- (NSData *)getIcyParmValueS:(NSString *)icyParmName inData:(NSData*)haystack
{
	NSUInteger startOfLine = [self indexOfData:icyParmName inData:haystack encoding:NSASCIIStringEncoding];
	if (startOfLine == NSNotFound) {
		return nil;
	}
	NSData *remainderData = [[NSData alloc] initWithData:[haystack subdataWithRange:(NSRange){startOfLine,[haystack length] - startOfLine}]];
	
	NSUInteger endOfLine = [self indexOfData:@"\r\n" inData:remainderData encoding:NSASCIIStringEncoding];
	NSData *line = [haystack subdataWithRange:(NSRange){startOfLine,endOfLine}];
	
	NSUInteger startOfParm = [self indexOfData:@":" inData:line encoding:NSASCIIStringEncoding] + 1;
	
	[remainderData release];
	
	return [line subdataWithRange:(NSRange){startOfParm,[line length]-startOfParm}];

}

+(NSString *) stringForFormatID:(UInt32) dataFormat {
	switch (dataFormat) {
		case kAudioFormatLinearPCM:
			return @"Linear PCM";
		case kAudioFormatAC3:
			return @"AC3";
		case kAudioFormatMPEGLayer1:
			return @"MP1";
		case kAudioFormatMPEGLayer2:
			return @"MP2";
		case kAudioFormatMPEGLayer3:
			return @"MP3";
		case kAudioFormatMPEG4CELP:
			return @"MP4_CDELP";
		case kAudioFormatMPEG4HVXC:
			return @"MP34_HVXC";
		case kAudioFormatMPEG4TwinVQ:
			return @"MP4_TwinVQ";
		case kAudioFormatMIDIStream:
			return @"MIDI";
		case kAudioFormatMPEG4AAC:
			return @"AAC";
		case kAudioFormatMPEG4AAC_HE:
			return @"AAC+";
		case kAudioFormatMPEG4AAC_LD:
			return @"AAC_LD";
		case kAudioFormatMPEG4AAC_HE_V2:
			return @"AAC_HE_V2";
		case kAudioFormatMPEG4AAC_Spatial:
			return @"AAC_Spatial";
		case kAudioFormatAppleLossless:
			return @"Apple Lossless";
		case kAudioFormatParameterValueStream:
			return @"Parameter Value Stream";
			
		case kAudioFormatDVIIntelIMA:
			return @"DVI Intel IMA";
		case kAudioFormatMicrosoftGSM:
			return @"MS GSM";

		default: {
			// convert to string
			char *fmtChars = (char *)&dataFormat;
			return [NSString stringWithFormat:@"%c%c%c%c", fmtChars[3], fmtChars[2], fmtChars[1], fmtChars[0]];
			
		}
	}
	
}

//
// stringForErrorCode:
//
// Converts an error code to a string that can be localized or presented
// to the user.
//
// Parameters:
//    anErrorCode - the error code to convert
//
// returns the string representation of the error code
//
+ (NSString *)stringForErrorCode:(AudioStreamerErrorCode)anErrorCode
{
	switch (anErrorCode)
	{
		case AS_NO_ERROR:
			return NSLocalizedStringFromTable(@"NoError", @"Errors", nil);
		case AS_FILE_STREAM_GET_PROPERTY_FAILED:
			return NSLocalizedStringFromTable(@"FileStreamGetPropertyFailed", @"Errors", nil);
		case AS_FILE_STREAM_SEEK_FAILED:
			return NSLocalizedStringFromTable(@"FileStreamSeekFailed", @"Errors", nil);
		case AS_FILE_STREAM_PARSE_BYTES_FAILED:
			return NSLocalizedStringFromTable(@"ParseBytesFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_CREATION_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueCreateFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED:
			return NSLocalizedStringFromTable(@"AudioBufferAllocationFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_ENQUEUE_FAILED:
			return NSLocalizedStringFromTable(@"QueueingAudioBufferFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_ADD_LISTENER_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueAddListenerFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueRemoveListenerFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_START_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueStartFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_BUFFER_MISMATCH:
			return NSLocalizedStringFromTable(@"AudioQueueBufferMismatch", @"Errors", nil);
		case AS_FILE_STREAM_OPEN_FAILED:
			return NSLocalizedStringFromTable(@"AudioFileStreamOpenFailed", @"Errors", nil);
		case AS_FILE_STREAM_HOST_UNREACHABLE:
			return NSLocalizedStringFromTable(@"StationWebsiteUnavailable", @"Errors", nil);
		case AS_FILE_STREAM_CLOSE_FAILED:
			return NSLocalizedStringFromTable(@"AudioFileStreamCloseFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_DISPOSE_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueDisposeFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_PAUSE_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueuePauseFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_FLUSH_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueFlushFailed", @"Errors", nil);
		case AS_AUDIO_DATA_NOT_FOUND:
			return NSLocalizedStringFromTable(@"NoAudioStream", @"Errors", nil);
		case AS_AUDIO_DATA_CONNECTION_TIMEOUT:
			return NSLocalizedStringFromTable(@"ConnectionTimeout", @"Errors", nil);
		case AS_AUDIO_DATA_CONNECTION_ERROR:
			return NSLocalizedStringFromTable(@"AudioStreamConnectionError", @"Errors", nil);
		case AS_AUDIO_DATA_CONNECTION_STREAM_ENDED:
			return NSLocalizedStringFromTable(@"AudioStreamEndedUnexpectedly", @"Errors", nil);
		case AS_GET_AUDIO_TIME_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueGetTimeFailed", @"Errors", nil);
		case AS_NETWORK_CONNECTION_FAILED:
			return NSLocalizedStringFromTable(@"NetworkConnectionFailed", @"Errors", nil);
		case AS_AUDIO_QUEUE_STOP_FAILED:
			return NSLocalizedStringFromTable(@"AudioQueueStopFailed", @"Errors", nil);
		case AS_AUDIO_STREAMER_FAILED:
			return NSLocalizedStringFromTable(@"AudioPlaybackFailed", @"Errors", nil);
		case AS_AUDIO_BUFFER_TOO_SMALL:
			return NSLocalizedStringFromTable(@"AudioPacketsTooLarge", @"Errors", nil);
		case AS_REQUEST_OPEN_FAILED:
			return NSLocalizedStringFromTable(@"RequestOpenFailed", @"Errors", nil);
		case AS_URL_OPEN_FAILED:
			return NSLocalizedStringFromTable(@"URLOpenFailed", @"Errors", nil);
		case AS_URL_NO_PLAYLIST:
			return NSLocalizedStringFromTable(@"URLNoPlaylist", @"Errors", nil);
		case AS_INCORRECT_SERVER_RESPONSE:
			return NSLocalizedStringFromTable(@"IncorrectServerResponse", @"Errors", nil);
		default:
			return NSLocalizedStringFromTable(@"AudioPlaybackUnknownError", @"Errors", nil);
	}
	
}

+ (NSString *) stringForState:(AudioStreamerState) streamerState {

	switch (streamerState)
	{
		case AS_INITIALIZED:
			return @"AS_INITIALIZED";
		case AS_STARTING_FILE_THREAD:
			return @"AS_STARTING_FILE_THREAD";
		case AS_WAITING_FOR_DATA:
			return @"AS_WAITING_FOR_DATA";
		case AS_WAITING_FOR_QUEUE_TO_START:
			return @"AS_WAITING_FOR_QUEUE_TO_START";
		case AS_PLAYING:
			return @"AS_PLAYING";
		case AS_BUFFERING:
			return @"AS_BUFFERING";
		case AS_STOPPING:
			return @"AS_STOPPING";
		case AS_STOPPED:
			return @"AS_STOPPED";
		case AS_PAUSED:
			return @"AS_PAUSED";
		case AS_GETPLAYLIST:
			return @"AS_GETPLAYLIST";
		case AS_STREAMER_STARTING:
			return @"AS_STREAMER_STARTING";
		case AS_ERROR_RETRY:
			return @"AS_ERROR_RETRY";
		default:
			return [NSString stringWithFormat:@"Unknown state=%d", streamerState];
	}
}

+ (NSString *) stringForStopReason: (AudioStreamerStopReason) stopCode {
	switch (stopCode)
	{
		case AS_NO_STOP:
			return @"AS_NO_STOP";
		case AS_STOPPING_EOF:
			return @"AS_STOPPING_EOF";
		case AS_STOPPING_USER_ACTION:
			return @"AS_STOPPING_USER_ACTION";
		case AS_STOPPING_ERROR:
			return @"AS_STOPPING_ERROR";
		case AS_STOPPING_TEMPORARILY:
			return @"AS_STOPPING_TEMPORARILY";
		default:
			return [NSString stringWithFormat:@"Unknown Stopping State=%d", stopCode];
	}
	
	return NSLocalizedStringFromTable(@"Audio playback failed due to an untrapped error", @"Errors", nil);
}

+ (NSString *) translateAudioFileStreamProperties:(UInt32)audioFileStreamProperty {
	
	// convert to string
	char *fmtChars = (char *)& audioFileStreamProperty;
	return [NSString stringWithFormat:@"%c%c%c%c", fmtChars[3], fmtChars[2], fmtChars[1], fmtChars[0]];
	
}

@end
