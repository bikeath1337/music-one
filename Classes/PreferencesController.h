//
//  PreferencesController.h
//  MusicOne
//
//  Created by Bobby Wallace on 01/27/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicPlayerAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import "HTMLSourceViewController.h"

@protocol PrefsControllerDelegate;


@interface PreferencesController : UIViewController <UITableViewDelegate, UITableViewDataSource, 
	UINavigationControllerDelegate,  MFMailComposeViewControllerDelegate, HTMLControllerDelegate> 
{
	id <PrefsControllerDelegate> delegate;
	NSUInteger selectedStationIndex;
	
	MusicPlayerAppDelegate *appDelegate;
	
	UITableViewCell * aboutCell, *switchCell;
}

@property (nonatomic, assign) id <PrefsControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITableViewCell *aboutCell, *switchCell;
@property NSUInteger selectedStationIndex;

- (IBAction)done;
- (IBAction)cancel;
- (IBAction)autoLockAction:(id)sender;

-(void) restore;
-(void)showPicker:(NSString *) toEmail subject:(NSString *) subject animated:(BOOL) animated;
-(void)displayComposerSheet:(NSString *) toEmail subject:(NSString *) subject animated:(BOOL) animated;
-(void)launchMailAppOnDevice:(NSString *) toEmail subject:(NSString *) subject;

- (void) showAbout:(BOOL) animated;
- (void) showSupport:(BOOL) animated;
- (void) showEmailStation:(BOOL) animated;
//- (void) showEmailDeveloper:(BOOL) animated;

@end

@protocol PrefsControllerDelegate
- (void)prefsViewControllerDidFinish:(PreferencesController *)controller;
- (void)prefsViewControllerDidCancel:(PreferencesController *)controller;
@end
