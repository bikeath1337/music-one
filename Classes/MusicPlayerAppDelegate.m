//
//  MusicOneCoreDataAppDelegate.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/04/2010.
//  Copyright Total Managed Fitness 2010. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#import "MusicPlayerAppDelegate.h"
#import "CustomerMusicPlayer.h"
#import "SongsTabBarController.h"
#import "TopSongsController.h"

@implementation MusicPlayerAppDelegate

@synthesize htmlCache;
@synthesize window;
@synthesize active, restoringState;
@synthesize navigationController;
@synthesize rootViewController;
@synthesize theStation;
@synthesize stationIndex;
@synthesize streamOptions;
@synthesize streamOption;

@synthesize savedNavigationStack;
@synthesize urlLists;

@synthesize songPredicate;

#pragma mark -
#pragma mark Application lifecycle

// +initialize is invoked before the class receives any other messages
/*
+ (void)initialize {
	
    if ([self class] == [MusicPlayerAppDelegate class]) {
		
    }
	
}
*/

- (void)dealloc {
	[managedObjectContext release];
	[managedObjectModel release];
	[persistentStoreCoordinator release];
	[savedNavigationStack release];
	
    [window release];
    [rootViewController release];
	[navigationController release];
    [super dealloc];
}

-(void) applicationDidReceiveMemoryWarning:(UIApplication *)application {

}
- (BOOL)application:(UIApplication *)uIapplication didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	application = uIapplication;

	self.htmlCache = [[NSMutableDictionary alloc] init];

	self.rootViewController = [[CustomerMusicPlayer alloc] init];
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	static NSString * resetDBKey = @"reset_database_on_next_start";
	BOOL resetDatabase = [defaults boolForKey:resetDBKey];

	if(resetDatabase){
		[self deletePersistentStore];
		[defaults removeObjectForKey:resetDBKey];
		[defaults setBool:NO forKey:[PlayerEventNotifications keyForStatus:AudioStreamerStationCreatedKey]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerCreateStreamOptions]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreStationIndexKey]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreNavigationStack]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerLastCleanupDate]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerLastVoteCleanupDate]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerPlayState]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreScrollPage]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreShowingPreferences]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreDetailSongID]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerFetchMissedSongs]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsAreFresh]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsLastFetchDate]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreSongTableSelectedRow]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsStationTimestamp]];
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	}
	
	NSManagedObjectContext *moc = self.managedObjectContext;
	if(moc !=nil){
		
		rootViewController.managedObjectContext = moc;
		
		BOOL dataCreated = [defaults boolForKey:[PlayerEventNotifications keyForStatus:AudioStreamerStationCreatedKey]];
		
		if(dataCreated) {
			self.theStation = (Station *) [self getStation];
			self.streamOptions = [self getStreamOptions];
		} else {
			
			[self clearRecents];
			self.theStation = [self createStation];
			self.streamOptions = [self createStreamOptions:self.theStation];
			
			[defaults setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerStationCreatedKey]];
			
		}
		
		BOOL streamOptionsCreated = [defaults boolForKey:[PlayerEventNotifications keyForStatus:AudioStreamerCreateStreamOptions]];
		if (!streamOptionsCreated) {
			self.streamOptions = [self createStreamOptions:self.theStation];
			[defaults setBool:YES forKey:[PlayerEventNotifications keyForStatus:AudioStreamerCreateStreamOptions]];
		}

		if(self.theStation == nil) {
			[defaults setBool:NO forKey:[PlayerEventNotifications keyForStatus:AudioStreamerStationCreatedKey]];
			[defaults synchronize];
			
			NSLog(@"No Station found in the database.");
			exit(0);
		}
		
		if(self.streamOptions == nil) {
			NSLog(@"No Stream Options found in the database.");
			exit(0);
		}
		
		if (nil == [defaults objectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreStationIndexKey]]) {
			// Choose the lowest resolution for those who haven't set it up yet
			self.stationIndex = 1;
		} else {
			self.stationIndex = [defaults integerForKey:[PlayerEventNotifications keyForStatus:StartupRestoreStationIndexKey]];
		}
		if (self.stationIndex <0 && self.stationIndex >= [self.streamOptions count]) {
			self.stationIndex = 0;
		}
		
		self.streamOption = [self.streamOptions objectAtIndex:self.stationIndex];
		
		self.urlLists = [NSMutableArray arrayWithCapacity:[self.streamOptions count]];
		
	}
	
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	navigationController.navigationBar.barStyle = 
			navigationController.toolbar.barStyle = UIBarStyleDefault;
	[navigationController setToolbarHidden:NO animated:NO];
	navigationController.delegate = rootViewController;

	self.restoringState = YES;

	[window addSubview:navigationController.view];
	[window addSubview:rootViewController.view];

	defaults = [NSUserDefaults standardUserDefaults];
	
	[self restore];
	
	[window makeKeyAndVisible];
	
	return YES;

}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self performSelector:@selector(saveState) withObject:nil];
}

-(void) applicationWillResignActive:(UIApplication *)app {
//	NSLog(@"App resigning active: state=%d", application.applicationState);
	self.active = NO;
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
	self.active = YES;
//	NSLog(@"did become active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//	NSLog(@"App going to background");
	[self performSelector:@selector(saveState) withObject:nil];
}
- (void)applicationWillEnterForeground:(UIApplication *)app {
	[rootViewController playerWillEnterForeground];
}
- (UIApplicationState) getApplicationState{
	return application.applicationState;
}

- (void) saveState {
	NSArray * navigationStack = navigationController.viewControllers;
	NSMutableArray * sa = [NSMutableArray arrayWithCapacity:[navigationStack count]];
	
	for (UIViewController * vc in navigationStack) {
		[sa addObject:[NSString stringWithFormat:@"%@", vc.class]];
	}
	
	if ([sa count]) {
		[defaults setObject:sa forKey:[PlayerEventNotifications keyForStatus:StartupRestoreNavigationStack]];
	} else {
		[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreNavigationStack]];
	}
}

- (void) restore {

	self.savedNavigationStack = [defaults objectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreNavigationStack]];
	[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:StartupRestoreNavigationStack]];

	[rootViewController restore];

	self.restoringState = NO;
}

#pragma mark -
#pragma mark Player Helper Methods

- (NSManagedObject *) getStation {
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:self.managedObjectContext]; 
	[request setEntity:entity];
	
	NSArray * fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error]; 
	NSManagedObject * station = nil;

	do {
		if (fetchResults == nil) {
			[self processError:error];
		}
		
		if([fetchResults count] ) {
			station = [fetchResults objectAtIndex:0];
		} else {
			NSLog(@"No Station found");
		}
	} while (NO);
	
	[request release];
	return station;
}

- (NSArray *) getStreamOptions {
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"StreamOption" inManagedObjectContext:self.managedObjectContext]; 
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:YES];
	[request setEntity:entity];
	[request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
	[sortDescriptor release];
	
	NSArray * fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error]; 
	NSArray * options = nil;
	
	do {
		if (fetchResults == nil) {
			[self processError:error];
		}
		
		if([fetchResults count] ) {
			options = [NSArray arrayWithArray:fetchResults];
		} else {
			NSLog(@"No Stream Options found");
		}
	} while (NO);
	
	[request release];
	return options;
}

- (NSNumber *) countOfSongs: (BOOL) favoritesOnly {
	
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	if(favoritesOnly)
		[request setPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"favorite == 1"]]];

	NSUInteger count = [managedObjectContext countForFetchRequest:request error:&error];
	
	[request release];

	return [NSNumber numberWithInteger:count];
}

- (NSNumber *) countOfRecents {
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentlyPlayed" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	
	NSError *error = nil;
	NSUInteger count = [managedObjectContext countForFetchRequest:request error:&error];
	
	[request release];
	
	return [NSNumber numberWithInteger:count];
}

- (Song *) findSong:(NSString *) newSongID {
	
	if(self.songPredicate == nil){
		// only parse the predicate once
		NSString * predString = [NSString stringWithFormat:@"songID == $SONG_ID"];
		self.songPredicate = [NSPredicate predicateWithFormat:predString];
	}
	
	NSNumber *nSongID = [NSNumber numberWithInt:[newSongID intValue]];
	NSDictionary *variables = [NSDictionary dictionaryWithObject:nSongID forKey:@"SONG_ID"]; 
	NSPredicate *localPredicate = [self.songPredicate predicateWithSubstitutionVariables:variables];
	
	NSError *error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	[request setPredicate:localPredicate];
	
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error]; 
	
	if (fetchResults == nil) {
		[self processError:error];
	}
	
	Song * song = nil;
	if([fetchResults count] ) {
		// NSLog(@"Found %d Song with ID=%@", [fetchResults count], nSongID);
		song = [fetchResults objectAtIndex:0];
	} else {
		// NSLog(@"Song not found with ID=%@",nSongID);
	}
	
	[request release];
	
	return song;
}

-(void) processError:(NSError *) error {
	NSLog(@"Error: %@", [error localizedDescription]); 
	NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey]; 
	if(detailedErrors != nil && [detailedErrors count] > 0) { 
		for(NSError* detailedError in detailedErrors) { 
			NSLog(@"DetailedError: %@", [detailedError userInfo]); 
		} 
	} 
	else { 
		NSLog(@"%@", [error userInfo]); 
	} 
}

#pragma mark -
#pragma mark Data Creation Methods

- (Station *) createStation {
	
	// Station
	NSError * error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	
	NSManagedObject * newStation = nil;
	
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error] ; 
	
	do {
		if (fetchResults == nil) {
			[self processError:error];
			break;
		}
		
		//NSLog(@"Stations count=%d", [mutableFetchResults count]);
		if ([fetchResults count] ) {
			// delete all
			for (NSManagedObject * obj in fetchResults) {
				[managedObjectContext deleteObject:obj];
			}
			if (![managedObjectContext save:&error]) {
				[self processError:error];
				break;
			}
		}
		
		newStation = [NSEntityDescription insertNewObjectForEntityForName:@"Station" inManagedObjectContext:managedObjectContext];
		
		[rootViewController createStation:newStation];
		
		if (![managedObjectContext save:&error]) {
			if(error != nil) { 
				[self processError:error];
				break;
			} 
		}
		
	} while (NO);
	
	[request release];
	
	return (Station *) newStation;
	
}

- (NSArray *) createStreamOptions:(Station *) station {
	// StreamOption
	NSError * error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"StreamOption" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	
	NSArray * options = nil;
	
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error]; 
	
	do {
		
		if (fetchResults == nil) {
			[self processError:error];
			break;
		}
		
		//NSLog(@"Stations count=%d", [mutableFetchResults count]);
		if ([fetchResults count] ) {
			// delete all
			for (NSManagedObject * obj in fetchResults) {
				[managedObjectContext deleteObject:obj];
			}
			if (![managedObjectContext save:&error]) {
				[self processError:error];
				break;
			}
		}
		
		options = [rootViewController createStreamOptions];
		
		[station addStreamOptions:[NSSet setWithArray:options]];
		
		if (![managedObjectContext save:&error]) {
			if(error != nil) { 
				[self processError:error];
				break;
			} 
		}
		
	} while (NO);
	
	[request release];
	
	return options;
}

- (void) clearRecents {
	
	// Recents
	NSError * error = nil;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentlyPlayed" inManagedObjectContext:managedObjectContext]; 
	[request setEntity:entity];
	
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error] ; 
	
	do {
		if (fetchResults == nil) {
			[self processError:error];
			break;
		}
		
		NSLog(@"RecentlyPlayed count=%d", [fetchResults count]);
		if ([fetchResults count] ) {
			// delete all
			for (NSManagedObject * obj in fetchResults) {
				[managedObjectContext deleteObject:obj];
			}
			if (![managedObjectContext save:&error]) {
				[self processError:error];
				break;
			}
		}
		
	} while (NO);
	
	[request release];
	
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"StreamingStation" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	
    return managedObjectModel;
}

- (NSString *) persistentStorePath {
	NSString *storeName = @"StreamingStation.sqlite";
    NSString *storePath = [MusicPlayerAppDelegate applicationDocumentsDirectory];
    NSString *storeFullPath = [storePath stringByAppendingPathComponent:storeName];
    return storeFullPath;
}

- (void) deletePersistentStore {
	NSString *storeFullPath = [self persistentStorePath];
	NSFileManager * fm = [[NSFileManager alloc] init];
	NSError *error = nil;
	if([fm fileExistsAtPath:storeFullPath]) {
		//		NSLog(@"Exists at: %@", storeFullPath);
		if([fm isDeletableFileAtPath:storeFullPath]) {
			//NSLog(@"can delete at: %@", storeFullPath);
			if(![fm removeItemAtPath:storeFullPath error:&error]) {
				[self processError:error];
			} else {
				NSLog(@"Persistent store deleted at %@", storeFullPath);
			}
		} else {
			NSLog(@"Persistent store not deleteable at %@", storeFullPath);

		}
	} else {
		NSLog(@"Persistent store not found at %@", storeFullPath);
		
	}

	[fm release];
}
/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
	NSString *storeFullPath = [self persistentStorePath];

    NSURL *storeUrl = [NSURL fileURLWithPath:storeFullPath];
	
	NSError *error = nil;
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		NSLog(@"Failed to open data store: %@", [error localizedDescription]); 
		
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey]; 
		if(detailedErrors != nil && [detailedErrors count] > 0) { 
			for(NSError* detailedError in detailedErrors) { 
				NSLog(@"DetailedError: %@", [detailedError userInfo]); 
			} 
		} 
		else { 
			NSLog(@"%@", [error userInfo]);
		} 

		NSString *prompt = NSLocalizedStringFromTable(@"ResetDatabase", @"Errors", nil);
		
		UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:[[error userInfo] objectForKey: @"reason"] 
															delegate:self
												   cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"Buttons", nil)
											  destructiveButtonTitle:prompt
												   otherButtonTitles:nil];
		[sheet showInView:window];
		
		[sheet release];
		
		return nil;
    }    
	
    return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
+ (NSString *)applicationDocumentsDirectory {
	//NSLog(@"AppDocsDirectory=%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

-(StreamOption *) setStationWithIndex:(NSUInteger)idx {
	if (idx>=0 || idx<[theStation.streamOptions count]) {
		self.stationIndex = idx;
		streamOption = [self.streamOptions objectAtIndex:self.stationIndex];
		[[NSUserDefaults standardUserDefaults] setInteger:stationIndex forKey:[PlayerEventNotifications keyForStatus:StartupRestoreStationIndexKey]];
		return streamOption;
	}
	return nil;
}

-(NSUInteger) getIndexOfStation:(StreamOption *) option {
	return [self.streamOptions indexOfObject:option];
}

- (NSArray *) getUrls {
    if ([urlLists count] == 0) {
		for(StreamOption * option in self.streamOptions){
			[self.urlLists addObject:[NSArray array]];
		}
    }
	
	NSArray * urlList = [self.urlLists objectAtIndex:self.stationIndex];
	
	if([urlList count] ) {
		return urlList;
	}
	
	NSURL *url = [NSURL URLWithString:self.streamOption.playlistUrl];
	Reachability * reachbilityOfHost = [Reachability reachabilityWithHostName:url.host];
	
	//NetworkStatus stat = [reachbilityOfHost currentReachabilityStatus];
	if(reachbilityOfHost.currentReachabilityStatus == NotReachable){
		return nil;
	}
	IniPreferences * prefs = [[IniPreferences alloc] initWithString:self.streamOption.playlistUrl encoding: NSUTF8StringEncoding];
	NSDictionary *urlDict = [prefs.sections objectForKey:@"playlist"];
	
	NSString *countOfItems = [urlDict objectForKey:@"numberofentries"];
	NSUInteger count = [countOfItems integerValue];
	NSMutableArray *keys = [[NSMutableArray alloc] init];
	
	for (NSUInteger i=1; i<=count; i++) {
		NSString *key = [@"file" stringByAppendingString:[[NSNumber numberWithInt:i] stringValue]];
		[keys addObject:key];
	}
	
	NSString *marker = @"not found";
	urlList = [urlDict objectsForKeys:keys notFoundMarker:marker];
	
	if([urlList count])
		[self.urlLists replaceObjectAtIndex:self.stationIndex withObject:urlList];
	
	[keys release];
	[prefs release];
	
	return urlList;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self deletePersistentStore];
		[defaults setBool:NO forKey:[PlayerEventNotifications keyForStatus:AudioStreamerStationCreatedKey]];
		UIAlertView *alert =
		[[[UIAlertView alloc]
		  initWithTitle:NSLocalizedStringFromTable(@"AskToResetTitle", @"Errors", nil)
		  message:NSLocalizedStringFromTable(@"AskToRestart", @"Errors", nil)
		  delegate:self
		  cancelButtonTitle:NSLocalizedStringFromTable(@"Exit", @"Buttons", nil)
		  otherButtonTitles: nil]
		 autorelease];
		[alert show];
		
	} else {
		exit(1);
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	exit(2);
}

@end

