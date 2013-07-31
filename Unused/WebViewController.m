//
//  WebView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/09/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "WebViewController.h"


@implementation WebViewController

@synthesize webView;
@synthesize webAddress;
@synthesize reloadStopButton;
@synthesize reloadButton;
@synthesize stopButton;
@synthesize backButton;
@synthesize forwardButton;

- (IBAction)loadURL:(id)sender {
	NSURL *wAddress = [NSURL URLWithString:self.webAddress.text];
	NSString *xxxx = [wAddress scheme];
	[webView loadRequest:[NSURLRequest requestWithURL:wAddress]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	return YES;
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSLog(@"%@", self.webAddress.text);
//	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.webAddress.text]]];

}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
