//
//  SongPickerView.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/18/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CoreDataEditingTableViewController.h"
#import "SongsTabBarController.h"
#import "MusicPlayerController.h"

#define SONGLABEL_TAG 1 
#define ARTISTMIXLABEL_TAG 2 
#define RECENTSLABEL_TAG 3
#define RATINGLABEL_TAG 4
#define NUMBERLABEL_TAG 5

typedef enum
{
	Recent = 0,
	Top,
	Favorite
} SongTableType;

@interface SongPickerView : CoreDataEditingTableViewController <CoreDataEditingTableViewDelegate>{
    SongsTabBarController *pickerViewController;
	
	SongTableType tableType;
	
}
@property (nonatomic, retain) IBOutlet SongsTabBarController *pickerViewController;
@property (nonatomic, assign) SongTableType tableType;

- (void)clearAll;
- (void)doClearAll;
- (void) doDelete: (NSManagedObject *) managedObject;
- (void) showDetail: (NSManagedObject *) managedObject animated:(BOOL) animated;
- (NSString *) tableHeader: (NSInteger) section;
- (void) clearCache;

@end
