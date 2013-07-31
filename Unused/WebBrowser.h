//
//  HtmlView.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/09/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebBrowser : UIViewController <UITextFieldDelegate, UIWebViewDelegate> {
	NSString * startUpUrl;
	
	UITextField *webAddress;
	UIView * titleView;
	UIToolbar *webToolbar;
	IBOutlet UIButton *test;
	
	UIBarButtonItem *bbWebAddress;
	UIBarButtonItem * reloadStopButton;
	UIBarButtonItem *reloadButton;
	UIBarButtonItem *stopButton;
	UIButton * backButton;
	UIButton * forwardButton;
	UIBarButtonItem * flexSpace;
	UIWebView * webView;
}
	
@property (nonatomic, retain) IBOutlet UIView *titleView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *bbWebAddress;
@property (nonatomic, retain) IBOutlet UITextField *webAddress;
@property (nonatomic, retain) IBOutlet UIToolbar *webToolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *reloadStopButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *reloadButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *stopButton;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *forwardButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *flexSpace;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (IBAction)loadURL:(id)sender;
- (void) updateWndow;
- (id) initWithURLString: (NSString *) urlString;
@end
