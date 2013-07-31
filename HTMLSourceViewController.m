//
//  AboutViewController.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/10/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "HTMLSourceViewController.h"
#import "MusicPlayerAppDelegate.h"

@implementation HTMLSourceViewController

@synthesize htmlView;
@synthesize activity;
@synthesize cacheKey;
@synthesize reloadButton;
@synthesize HTMLdelegate;

- (id) initWithTitle: (NSString *) viewTitle URLString: (NSString *) urlString {
	if( self = [super init] ) {
		startUpUrl = urlString;
	}
	self.title = viewTitle;
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if([startUpUrl length]) {

		MusicPlayerAppDelegate *appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
		
		if (cacheKey != nil) {
			NSString * cachedHTML = [appDelegate.htmlCache objectForKey:cacheKey];
			if (cachedHTML != nil) {
				[htmlView loadHTMLString:cachedHTML baseURL:[NSURL URLWithString:startUpUrl]];
			} else {
				[self reload];
			}
		}
	}
	
	self.navigationItem.title = self.title;

	self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
	[self.navigationItem setRightBarButtonItem:reloadButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {
	MusicPlayerAppDelegate *appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[appDelegate.htmlCache objectForKey:cacheKey];

    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.htmlView = nil;
	self.activity = nil;
	self.reloadButton = nil;
}

- (void)dealloc {
	[htmlView release];
	[activity release];
	[reloadButton release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webViewObj {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[activity stopAnimating];
	
	//[self performSelectorInBackground:@selector(loadCache) withObject:nil];
}
- (void)webView:(UIWebView *)webViewObj didFailLoadWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[activity stopAnimating];
	
	// report the error inside the htmlview
	NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+5 color='red'>%@ - %@</font></center></html>",
							 NSLocalizedStringFromTable(@"ErrorOccurred", @"Errors", nil), error.localizedDescription];
	
	[htmlView loadHTMLString:errorString baseURL:nil];
	
	self.navigationItem.prompt = @"Failed Request";
	
}

-(void) loadCache { // background task
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSError *error = nil;
	NSURL *wAddress = [NSURL URLWithString:startUpUrl];
	NSString * cachedHTML = [NSString stringWithContentsOfURL:wAddress encoding:NSUTF8StringEncoding error:&error];
	if (error == nil) {
		MusicPlayerAppDelegate *appDelegate = (MusicPlayerAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate.htmlCache setObject:cachedHTML forKey:cacheKey];
	}
	[pool drain];
}

- (void) reload {
	[htmlView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:startUpUrl]]];
}

- (IBAction)done {
	[self.HTMLdelegate HTMLViewControllerDidFinish:self];	
}

@end
