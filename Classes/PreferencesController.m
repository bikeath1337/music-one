//
//  PreferencesController.m
//  MusicOne
//
//  Created by Bobby Wallace on 01/27/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "PreferencesController.h"
#import "MusicPlayerAppDelegate.h"
#import "PlayerEventNotifications.h"
#import "HTMLSourceViewController.h"
#import "MusicPlayerController.h"


#define DEVELOPER_CONTACT_EMAIL @"bikeath1337@mac.com"

enum  {
	kPrefsSectionStreamingOptions = 0,
	kPrefsSectionSettings,
	kPrefsSectionInfo,
	kPrefsSectionStats
} PrefsSections;

enum {
	kInfoControllerSectionSupport = 0,
	kInfoControllerSectionAbout,
	kInfoControllerSectionContact,
	//	kInfoControllerAuto,
	//kInfoControllerSectionEntities,
	kInfoControllerSectionSongs
} InfoControllerSection;

@implementation PreferencesController

@synthesize delegate;
@synthesize selectedStationIndex;
@synthesize aboutCell, switchCell;

- (IBAction)done {
	[self.delegate prefsViewControllerDidFinish:self];	
}

- (IBAction)cancel {
	[self.delegate prefsViewControllerDidCancel:self];	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedStringFromTable(@"More", @"App", nil);

	appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	selectedStationIndex = appDelegate.stationIndex;
	
	UIBarButtonItem * done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
	[self.navigationItem setRightBarButtonItem:done animated:YES];
	[done release];

	self.navigationController.delegate = self;
	
	[self restore];

}

- (void)viewDidUnload {
	self.aboutCell = nil;
	self.switchCell = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[aboutCell release];
	[switchCell release];
	
    [super dealloc];
}

- (void) restore {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *windowType = [defaults objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	[defaults removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	//NSLog(@"%@", windowType);
	if([windowType isEqual:@"About"]){
		[self showAbout:NO];
	}else if ([windowType isEqual:@"Support"]){
		[self showSupport:NO];
	} else if([windowType isEqual:@"EmailStation"]){
		// fix showing the modal within the modal...
		//[self showEmailStation:NO];
	}

}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	if ([viewController isEqual:self]) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	switch (section) {
		case kPrefsSectionStreamingOptions:
			return [appDelegate.streamOptions count];
		case kPrefsSectionSettings:
			return 1;
		case kPrefsSectionInfo:
			return 3;
		case kPrefsSectionStats:
			return 6;
		default:
			return 1;
	}

}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *reuseIdentifier = @"PrefsCellIdentifier";
	static NSString *reuseSettingsIdentifier = @"SettingsCellIdentifier";
	static NSString *reuseAboutIdentifier = @"PrefsAboutCellIdentifier";
	static NSString *reuseIdentifierApp = @"AppCellIdentifier";
	
    UITableViewCell *cell = nil;
    
	switch (indexPath.section) {
		case kPrefsSectionStreamingOptions:
			cell = [table dequeueReusableCellWithIdentifier:reuseIdentifier];
			
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier] autorelease];
			}
			StreamOption *option= [appDelegate.streamOptions objectAtIndex:indexPath.row];
			
			cell.textLabel.text = NSLocalizedStringFromTable(option.streamDescription, @"App", nil);
			cell.detailTextLabel.text = NSLocalizedStringFromTable(option.bpsDescription, @"App", nil);
			
			if (appDelegate.stationIndex == indexPath.row) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}

			break;
		case kPrefsSectionSettings:
			cell = [table dequeueReusableCellWithIdentifier:reuseSettingsIdentifier];
			if (cell == nil) {
				[[NSBundle mainBundle] loadNibNamed:@"SwitchCell" owner:self options:nil];
				cell = switchCell;
				self.switchCell = nil;
			}
			
			UILabel *txt = (UILabel *)[cell viewWithTag:1];
			txt.text = NSLocalizedStringFromTable(@"Auto-Lock", @"Tables",nil);
					
			UISwitch * swAL = (UISwitch *)[cell viewWithTag:2];
			NSString * autoLockKey = [PlayerEventNotifications keyForStatus:AudioStreamerAutoLock];
			swAL.on = [[NSUserDefaults standardUserDefaults] boolForKey:autoLockKey];
			break;
		case kPrefsSectionInfo:
			cell = [table dequeueReusableCellWithIdentifier:reuseIdentifierApp];
			
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifierApp] autorelease];
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
					//				case kInfoControllerSectionContactDeveloper: {
					//textValue = NSLocalizedStringFromTable(@"Contact Developer", @"Tables",nil);
					//break;
					//}
					//	if (TARGET_IPHONE_SIMULATOR){
					//	case kInfoControllerSectionEntities: {
					//	textValue = NSLocalizedStringFromTable(@"Entities", @"Tables",nil);
					//	break;
					//}
					//}
				default: {
					textValue = NSLocalizedStringFromTable(@"Error Value", @"Errors", nil);
					break;
				}
			}
			cell.textLabel.text = textValue;
			break;
		case kPrefsSectionStats:
			cell = [table dequeueReusableCellWithIdentifier:reuseAboutIdentifier];
			
			if (cell == nil) {
				[[NSBundle mainBundle] loadNibNamed:@"AboutTableCell" owner:self options:nil];
				cell = aboutCell;
				self.aboutCell = nil;
			}
			
			static NSDateFormatter *dateFormatter = nil;
			if (dateFormatter == nil) {
				dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateStyle:NSDateFormatterShortStyle];
				[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
			}
			
			static NSNumberFormatter *numberFormatter = nil;
			if (numberFormatter == nil) {
				numberFormatter = [[NSNumberFormatter alloc] init];
				[numberFormatter setLocale:[NSLocale currentLocale]];
				[numberFormatter setUsesGroupingSeparator:YES];
				if ([numberFormatter groupingSize] == 0) {
					[numberFormatter setGroupingSize:3];
				}
			}
			
			UILabel *label = (UILabel *)[cell viewWithTag:1];
			NSNumber * count;
			
			switch (indexPath.row) {
				case 0:
					label.text =  NSLocalizedStringFromTable(@"Version", @"App",  nil);
					
					NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
					label = (UILabel *)[cell viewWithTag:2];
					label.text = version;
					break;
				case 1:
					label.text = NSLocalizedStringFromTable(@"Favorites", @"App", nil);
					
					count = [appDelegate countOfSongs:YES];
					label = (UILabel *)[cell viewWithTag:2];
					label.text = (count == nil) ? @"???" : [numberFormatter stringFromNumber:count];
					break;
				case 2:
					label.text = NSLocalizedStringFromTable(@"Recents", @"Tables", nil);
					
					count = [appDelegate countOfRecents];
					label = (UILabel *)[cell viewWithTag:2];
					label.text = (count == nil) ? @"???" : [numberFormatter stringFromNumber:count];
					break;
				case 3:
					label.text = NSLocalizedStringFromTable(@"CachedSongs", @"App", nil);
					
					count = [appDelegate countOfSongs:NO];
					label = (UILabel *)[cell viewWithTag:2];
					label.text = (count == nil) ? @"???" : [numberFormatter stringFromNumber:count];
					break;
				case 4:
					label.text = NSLocalizedStringFromTable(@"Song Refresh", @"App", nil);
					NSDate * lastTopSongsRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerTopSongsLastFetchDate]];
					
					label = (UILabel *)[cell viewWithTag:2];
					label.text = [dateFormatter stringFromDate:lastTopSongsRefreshDate];
					break;
				case 5:
					label.text = NSLocalizedStringFromTable(@"Cleanup", @"App", nil);
					NSDate * lastCleanupDate = [[NSUserDefaults standardUserDefaults] objectForKey:[PlayerEventNotifications keyForStatus:AudioStreamerLastCleanupDate]];
					
					label = (UILabel *)[cell viewWithTag:2];
					label.text = [dateFormatter stringFromDate:lastCleanupDate];
					break;
				default:
					break;
			}
			break;
		default:
			break;
	}

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kPrefsSectionStreamingOptions:
			return NSLocalizedStringFromTable(@"Streaming Options", @"App",nil);
		case kPrefsSectionSettings:
			return NSLocalizedStringFromTable(@"Settings", @"App",nil);;
		case kPrefsSectionInfo:
			return NSLocalizedStringFromTable(@"AboutStation", @"App",nil);
		case kPrefsSectionStats:
			return NSLocalizedStringFromTable(@"Application", @"App", nil);
		default:
			return @"Unknown";
	}

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == kPrefsSectionSettings || indexPath.section == kPrefsSectionStats){
		return nil;
	}
	return indexPath;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	// When a new selection is made, display a check mark on the newly-selected option
	// and remove check mark from old option.
	
	NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:selectedStationIndex inSection:newIndexPath.section];

	switch (newIndexPath.section) {
		case kPrefsSectionStreamingOptions:
			[[table cellForRowAtIndexPath:oldIndexPath] setAccessoryType:UITableViewCellAccessoryNone];
			[[table cellForRowAtIndexPath:newIndexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
			selectedStationIndex = newIndexPath.row;
			break;
		case kPrefsSectionSettings:
			break;
		case kPrefsSectionInfo:
			switch (newIndexPath.row) {
				case kInfoControllerSectionAbout: {
					[self showAbout:YES];
					break;
				}
				case kInfoControllerSectionSupport: {
					[self showSupport:YES];
					break;
				}
				case kInfoControllerSectionContact: {
					[self showEmailStation:YES];
					break;
				}
					//				case kInfoControllerSectionContactDeveloper: {
					//[self showEmailDeveloper:YES];
					//break;
					//}
					//if (TARGET_IPHONE_SIMULATOR){
					//case kInfoControllerSectionEntities: {
						//EntityListController *controller = [[EntityListController alloc] init];
						//controller.managedObjectModel = appDelegate.managedObjectModel;
						//controller.managedObjectContext = appDelegate.managedObjectContext;
						
						//[self.navigationController pushViewController:controller animated:YES];
						
						//[controller release];
						//break;
						//}
						//}
				default: {
					break;
				}
			}			
			break;
		case kPrefsSectionStats:
			break;
		default:
			break;
	}
    
    [table deselectRowAtIndexPath:newIndexPath animated:YES];
	
}

-(void)showPicker:(NSString *) toEmail subject:(NSString *) subject animated:(BOOL) animated
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
			[self displayComposerSheet: toEmail subject:subject animated:animated];
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
-(void)displayComposerSheet:(NSString *) toEmail subject:(NSString *) subject animated:(BOOL)animated
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	[picker setSubject:subject];
	
	// Set up recipients
	NSArray *toRecipients = [NSArray arrayWithObject:toEmail]; 
	
	[picker setToRecipients:toRecipients];
	
	[picker setMessageBody:@"" isHTML:YES];
	picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:picker animated:animated];
	
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
			message = NSLocalizedStringFromTable(@"SendCanceled", @"Mail", nil);
			ok = YES;
			break;
		case MFMailComposeResultSaved:
			message = NSLocalizedStringFromTable(@"SendSaved", @"Mail", nil);
			break;
		case MFMailComposeResultSent:
			message = NSLocalizedStringFromTable(@"SendSent", @"Mail", nil);
			ok = YES;
			break;
		case MFMailComposeResultFailed:
			message = NSLocalizedStringFromTable(@"SendNotSent", @"Mail", nil);
			break;
		default:
			message = NSLocalizedStringFromTable(@"SendFailed", @"Mail", nil);
			break;
	}
	
	if (ok) {
		[self dismissModalViewControllerAnimated:YES];
		return;
	}
	
	UIAlertView *alert =
	[[[UIAlertView alloc]
	  initWithTitle:NSLocalizedStringFromTable(@"SendError", @"Mail", nil)
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

- (void) showAbout:(BOOL) animated {
	
	[[NSUserDefaults standardUserDefaults] setObject:@"About" forKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	
	HTMLSourceViewController *about = [[HTMLSourceViewController alloc] initWithTitle:NSLocalizedStringFromTable(@"AboutStation", @"Owner", nil) URLString:[appDelegate.rootViewController aboutURL]];
	about.cacheKey = [PlayerEventNotifications keyForStatus:AudioStreamerHTMLAbout];
	about.HTMLdelegate = self;
	
	[self.navigationController pushViewController:about animated:animated];

	[about release];
}

- (void) showSupport:(BOOL) animated {
	[[NSUserDefaults standardUserDefaults] setObject:@"Support" forKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	
	HTMLSourceViewController *support = [[HTMLSourceViewController alloc] initWithTitle:NSLocalizedStringFromTable(@"Support Info", @"Owner", nil) URLString:[appDelegate.rootViewController supportURL]];
	support.cacheKey = [PlayerEventNotifications keyForStatus:AudioStreamerHTMLSupport];
	support.HTMLdelegate = self;

	[self.navigationController pushViewController:support animated:animated];
	
	[support release];
}

- (void) showEmailStation:(BOOL) animated {
	[[NSUserDefaults standardUserDefaults] setObject:@"EmailStation" forKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	[self showPicker:appDelegate.theStation.stationEmailAddress subject:NSLocalizedStringFromTable(@"Contact Us", @"Tables", nil) animated:animated];
}
/*
- (void) showEmailDeveloper:(BOOL) animated{
	[[NSUserDefaults standardUserDefaults] setObject:@"EmailDeveloper" forKey:[PlayerEventNotifications keyForStatus:AudioStreamerMoreDetail]];
	[self showPicker:DEVELOPER_CONTACT_EMAIL subject:NSLocalizedStringFromTable(@"ContactDeveloperMailSubject", @"Mail", nil) animated:animated];
}
*/
- (void)HTMLViewControllerDidFinish:(HTMLSourceViewController *)controller {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)autoLockAction:(id)sender
{
	NSString * autoLockKey = [PlayerEventNotifications keyForStatus:AudioStreamerAutoLock];
	[[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:autoLockKey];
	
	[appDelegate.rootViewController performSelector:@selector(batteryStateDidChange:) withObject:nil];

}

@end
