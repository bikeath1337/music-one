//
//  HtmlView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/09/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "WebBrowser.h"


@implementation WebBrowser

@synthesize webView;
@synthesize titleView;
@synthesize webToolbar;
@synthesize bbWebAddress;
@synthesize webAddress;
@synthesize reloadStopButton;
@synthesize reloadButton;
@synthesize stopButton;
@synthesize backButton;
@synthesize forwardButton;
@synthesize flexSpace;

#pragma mark -
#pragma mark Instance Methods

- (IBAction)loadURL:(id)sender {
	NSURL *wAddress = [NSURL URLWithString:self.webAddress.text];
	
	if([wAddress scheme] == nil) {
		NSString *newAddress = [self.webAddress.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		wAddress = [NSURL URLWithString:[@"http://" stringByAppendingString:newAddress]];
	}

	[webView loadRequest:[NSURLRequest requestWithURL:wAddress]];
}

- (void) updateWndow {
	self.backButton.enabled = webView.canGoBack;
	self.forwardButton.enabled = webView.canGoForward;
	
}

#pragma mark -
#pragma mark UIViewController

- (id) initWithURLString:(NSString *) urlString {
	[super init];
	
	startUpUrl = urlString;

	return self;
}
	

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self updateWndow];
	
	if([startUpUrl length]) {
		self.webAddress.text = startUpUrl;
		[self loadURL:nil];
	}
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
 }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.webView = nil;
	self.webToolbar = nil;
	self.webAddress = nil;
	self.reloadButton = nil;
	self.reloadStopButton = nil;
	self.stopButton = nil;
	self.backButton = nil;
	self.forwardButton = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	webView.delegate = self;	// setup the delegate as the web view is shown

	// self.title = @"MusicOne Browser";

}

- (void)viewWillDisappear:(BOOL)animated
{
    [webView stopLoading];	// in case the web view is still loading its content
	webView.delegate = nil;	// disconnect the delegate as the webview is hidden
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)dealloc {
	webView.delegate = nil;
	[webView release];
	[webToolbar release];
	[webAddress release];
	[reloadButton release];
	[reloadStopButton release];
	[stopButton release];
	[backButton release];
	[forwardButton release];
    [super dealloc];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webViewObj {
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.webAddress.text = [[webViewObj.request mainDocumentURL] absoluteString];
	[self updateWndow];
}
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
- (void)webView:(UIWebView *)webViewObj didFailLoadWithError:(NSError *)error {
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// report the error inside the webview
	
	NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+5 color='red'>%@ - %@</font></center></html>",
							 NSLocalizedStringFromTable(@"ErrorOccurred", @"Errors", nil), error.localizedDescription];
	[webViewObj loadHTMLString:errorString baseURL:nil];

	self.navigationItem.prompt = @"Failed Request";

	[self updateWndow];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	[self loadURL:nil];
	
	return YES;
}



@end
