//
//  AboutViewController.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/10/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HTMLControllerDelegate;


@interface HTMLSourceViewController : UIViewController <UIWebViewDelegate>{
	NSString * startUpUrl;

	UIActivityIndicatorView *activity;
	UIWebView *htmlView;
	UIBarButtonItem *reloadButton;
	
	NSString *cacheKey;
	
	id <HTMLControllerDelegate> HTMLdelegate;

}

@property (nonatomic, assign) id <HTMLControllerDelegate> HTMLdelegate;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, retain) UIBarButtonItem *reloadButton;
@property (nonatomic, retain) IBOutlet UIWebView *htmlView;
@property (nonatomic, assign) NSString *cacheKey;

- (id) initWithTitle: (NSString *) title URLString: (NSString *) urlString;
- (void) reload;
- (IBAction)done;

@end

@protocol HTMLControllerDelegate
- (void)HTMLViewControllerDidFinish:(HTMLSourceViewController *)controller;
@end