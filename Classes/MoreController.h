//
//  MoreController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/05/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "MusicPlayerAppDelegate.h"

enum {
	kInfoControllerSectionSupport = 0,
	kInfoControllerSectionAbout,
	kInfoControllerSectionContact,
	kInfoControllerSectionContactDeveloper,
	kInfoControllerSectionEntities,
	kInfoControllerSectionSongs
} InfoControllerSection;

@interface MoreController : UITableViewController <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate> {

	NSArray * sectionTitles;
	
	NSUInteger lastSelectedBandwidthRow;
	
	MusicPlayerAppDelegate *appDelegate;
	
}

@property (nonatomic, retain) NSArray * sectionTitles;
@property (nonatomic, assign) MusicPlayerAppDelegate * appDelegate;

-(void)showPicker:(NSString *) toEmail subject:(NSString *) subject;
-(void)displayComposerSheet:(NSString *) toEmail subject:(NSString *) subject;
-(void)launchMailAppOnDevice:(NSString *) toEmail subject:(NSString *) subject;

- (void) showAbout;
- (void) showSupport;

@end

