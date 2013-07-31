//
//  MoreController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/05/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "MoreController.h"
#import "HTMLSourceViewController.h"
#import "SongsTabBarController.h"
#import "EntityListController.h"
#import "MusicPlayerController.h"
#import "PlayerEventNotifications.h"

#define DEVELOPER_CONTACT_EMAIL @"bikeath1337@mac.com"

@implementation MoreController

@synthesize sectionTitles;
@synthesize appDelegate;

- (void)loadView {
	
	CGRect viewFrame = {{0,0}, [UIScreen mainScreen].applicationFrame.size};
	UITableView *view = [[UITableView alloc] initWithFrame:viewFrame];
	
	view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	view.dataSource = self;
	view.delegate = self;

	self.view = view;
	
	[view release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];

	self.title = NSLocalizedStringFromTable(@"More", @"Buttons", nil);
	
	/*
	NSString * detail = [[NSUserDefaults standardUserDefaults]  objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	
	if(detail == @"About") {
		[self showAbout];
	} else {
		[self showSupport];
	}
*/
	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	if (TARGET_IPHONE_SIMULATOR){
		return 5;
	}
	return 4;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *reuseIdentifier0 = @"MoreCellIdentifier";
	
    UITableViewCell *cell;
	
	cell = [table dequeueReusableCellWithIdentifier:reuseIdentifier0];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier0] autorelease];
	}
	
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	NSString *textValue;
	switch (indexPath.row) {
		case kInfoControllerSectionContact: {
			textValue = NSLocalizedStringFromTable(@"Contact Us", @"Tables",nil);
			break;
		}
		case kInfoControllerSectionSupport: {
			textValue = NSLocalizedStringFromTable(@"Support Information", @"Tables",nil);
			break;
		}
		case kInfoControllerSectionAbout: {
			textValue = NSLocalizedStringFromTable(@"About Us", @"Tables",nil);
			break;
		}
		case kInfoControllerSectionContactDeveloper: {
			textValue = NSLocalizedStringFromTable(@"Contact Developer", @"Tables",nil);
			break;
		}
if (TARGET_IPHONE_SIMULATOR){
		case kInfoControllerSectionEntities: {
			textValue = NSLocalizedStringFromTable(@"Entities", @"Tables",nil);
			break;
		}
}
		default: {
			textValue = NSLocalizedStringFromTable(@"Error Value", @"Errors", nil);
			break;
		}
	}
	cell.textLabel.text = textValue;

    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *rowToSelect = indexPath;
    
	[tableView deselectRowAtIndexPath:rowToSelect animated:YES];
	return rowToSelect;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	switch (newIndexPath.row) {
		case kInfoControllerSectionAbout: {
			[self showAbout];
			break;
		}
		case kInfoControllerSectionSupport: {
			[self showSupport];
			break;
		}
		case kInfoControllerSectionContact: {
			[self showPicker:appDelegate.theStation.stationEmailAddress subject:NSLocalizedStringFromTable(@"Contact Us", @"Tables", nil)];
			break;
		}
		case kInfoControllerSectionContactDeveloper: {
			[self showPicker:DEVELOPER_CONTACT_EMAIL subject:NSLocalizedStringFromTable(@"Contact Developer", @"Mail", nil)];

			break;
		}
if (TARGET_IPHONE_SIMULATOR){
		case kInfoControllerSectionEntities: {
			EntityListController *controller = [[EntityListController alloc] init];
			controller.managedObjectModel = appDelegate.managedObjectModel;
			controller.managedObjectContext = appDelegate.managedObjectContext;
			
			[self.navigationController pushViewController:controller animated:YES];
			
			[controller release];
			break;
		}
}
		default: {
			break;
		}
	}

	[table deselectRowAtIndexPath:newIndexPath animated:YES];

}

- (void)viewDidUnload {
	self.sectionTitles = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[sectionTitles release];
	
    [super dealloc];
}

-(void)showPicker:(NSString *) toEmail subject:(NSString *) subject
{
	// This sample can run on devices running iPhone OS 2.0 or later  
	// The MFMailComposeViewController class is only available in iPhone OS 3.0 or later. 
	// So, we must verify the existence of the above class and provide a workaround for devices running 
	// earlier versions of the iPhone OS. 
	// We display an email composition interface if MFMailComposeViewController exists and the device can send emails.
	// We launch the Mail application on the device, otherwise.
	
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if (mailClass != nil)
	{
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail])
		{
			[self displayComposerSheet: toEmail subject:subject];
		}
		else
		{
			[self launchMailAppOnDevice: toEmail subject:subject];
		}
	}
	else
	{
		[self launchMailAppOnDevice: toEmail subject:subject];
	}
}


#pragma mark -
#pragma mark Compose Mail

// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(void)displayComposerSheet:(NSString *) toEmail subject:(NSString *) subject
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	[picker setSubject:subject];
	
	// Set up recipients
	NSArray *toRecipients = [NSArray arrayWithObject:toEmail]; 
	
	[picker setToRecipients:toRecipients];
	
	[picker setMessageBody:@"" isHTML:YES];
	picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:picker animated:YES];

    [picker release];
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	// Notifies users about errors associated with the interface
	NSString *message;
	BOOL ok = NO;
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message = NSLocalizedStringFromTable(@"Canceled", @"Mail", nil);
			ok = YES;
			break;
		case MFMailComposeResultSaved:
			message = NSLocalizedStringFromTable(@"Saved", @"Mail", nil);
			break;
		case MFMailComposeResultSent:
			message = NSLocalizedStringFromTable(@"Sent", @"Mail", nil);
			ok = YES;
			break;
		case MFMailComposeResultFailed:
			message = NSLocalizedStringFromTable(@"Message not sent", @"Mail", nil);
			break;
		default:
			message = NSLocalizedStringFromTable(@"Failed to send message", @"Mail", nil);
			break;
	}
	
	if (ok) {
		[self dismissModalViewControllerAnimated:YES];
		return;
	}

	UIAlertView *alert =
	[[[UIAlertView alloc]
	  initWithTitle:NSLocalizedStringFromTable(@"Send Error", @"Errors", nil)
	  message:message
	  delegate:self
	  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Buttons", nil)
	  otherButtonTitles: nil]
	 autorelease];
	
	[alert show];

}


#pragma mark -
#pragma mark Workaround

// Launches the Mail application on the device.
-(void)launchMailAppOnDevice:(NSString *) toEmail subject:(NSString *) subject
{

	NSString *email = toEmail;
	[email stringByAppendingString:subject];
	[email stringByAppendingString:@""];

	email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (void) showAbout {

	[[NSUserDefaults standardUserDefaults] setObject:@"About" forKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];

	HTMLSourceViewController *about = [[HTMLSourceViewController alloc] initWithTitle:NSLocalizedStringFromTable(@"About Music One", @"Owner", nil) URLString:[appDelegate.playerController aboutURL]];
	about.cacheKey = [PlayerEventNotifications keyForStatus:AudioStreamerHTMLAbout];
	[self.navigationController pushViewController:about animated:YES];
	[about release];
}

- (void) showSupport {
	[[NSUserDefaults standardUserDefaults] setObject:@"Support" forKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	
	HTMLSourceViewController *support = [[HTMLSourceViewController alloc] initWithTitle:NSLocalizedStringFromTable(@"Support Info", @"Owner", nil) URLString:[appDelegate.playerController supportURL]];
	support.cacheKey = [PlayerEventNotifications keyForStatus:AudioStreamerHTMLSupport];
	[self.navigationController pushViewController:support animated:YES];
	[support release];
}

@end
