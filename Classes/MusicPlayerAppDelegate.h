//
//  MusicOneCoreDataAppDelegate.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/04/2010.
//  Copyright Total Managed Fitness 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "Station.h"
#import "StreamOption.h"

@class MusicPlayerController;

@interface MusicPlayerAppDelegate : NSObject <UIApplicationDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
    
    UIWindow *window;
    MusicPlayerController *rootViewController;
	UINavigationController *navigationController;
	
	UIApplication *application;
	
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;	    
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	
	BOOL active;
	Station *  theStation;
	NSUInteger stationIndex;
	
	StreamOption *streamOption;
	NSArray * streamOptions;
	
	NSMutableArray *urlLists;
	
	NSPredicate *songPredicate;

	NSUserDefaults *defaults;
	
	NSMutableDictionary *htmlCache;
	
	NSArray * savedNavigationStack;
	BOOL restoringState;
	
	BOOL backgroundSupported;

}

@property (nonatomic, retain) NSArray * savedNavigationStack;
@property (nonatomic, retain) NSMutableDictionary * htmlCache;
@property (nonatomic, assign) BOOL active, restoringState;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) MusicPlayerController *rootViewController;
@property (nonatomic, assign) UINavigationController *navigationController;
@property (nonatomic, retain) Station *theStation;
@property (nonatomic) NSUInteger stationIndex;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) NSArray * streamOptions;
@property (nonatomic, assign) StreamOption *streamOption;
@property (nonatomic, retain) NSMutableArray *urlLists;

@property (nonatomic, retain) NSPredicate *songPredicate;

-(StreamOption *) setStationWithIndex:(NSUInteger)idx;
-(NSUInteger) getIndexOfStation:(StreamOption *) option;
-(void) processError:(NSError *) error;
- (NSArray *) getUrls;

- (Station *) createStation; 
- (NSArray *) createStreamOptions:(Station *) station;
- (void) clearRecents;

- (NSManagedObject *) getStation;
- (NSArray *) getStreamOptions;

+ (NSString *)applicationDocumentsDirectory;
- (NSString *) persistentStorePath;
- (void) deletePersistentStore;


- (Song *) findSong:(NSString *) newSongID;
- (NSNumber *) countOfSongs:(BOOL) favoritesOnly;
- (NSNumber *) countOfRecents;
- (UIApplicationState) getApplicationState;
- (void) restore;
@end

