//
//  WebView.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/09/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>{
	UITextField *webAddress;
	UIBarButtonItem * reloadStopButton;
	UIBarButtonItem *reloadButton;
	UIBarButtonItem *stopButton;
	UIBarButtonItem * backButton;
	UIBarButtonItem * forwardButton;
	UIWebView * webView;
}

@property (nonatomic, retain) IBOutlet UITextField *webAddress;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *reloadStopButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *reloadButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *stopButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (IBAction)loadURL:(id)sender;


@end
