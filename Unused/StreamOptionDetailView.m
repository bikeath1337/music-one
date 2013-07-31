//
//  StreamOptionDetailView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/15/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "StreamOptionDetailView.h"


@implementation StreamOptionDetailView

@synthesize priority;
@synthesize playlistUrl;
@synthesize urlString;
@synthesize icyMetaTitleCompliant;
@synthesize streamType;
@synthesize serverType;
@synthesize contentType;
@synthesize streamDescription;

- (void)viewDidUnload {
	
	self.priority = nil;
	self.playlistUrl = nil;
	self.urlString = nil;
	self.icyMetaTitleCompliant = nil;
	self.streamType = nil;
	self.serverType = nil;
	self.contentType = nil;
	self.streamDescription = nil;
	
    [super viewDidUnload];
}

- (void)dealloc {
	[priority release];
	[playlistUrl release];
	[urlString release];
	[icyMetaTitleCompliant release];
	[streamType release];
	[serverType release];
	[contentType release];
	[streamDescription release];

    [super dealloc];
}


- (void) loadDataFromManagedObject {
	
	self.priority.text = [[managedObject valueForKey:@"priority"] stringValue];
	self.playlistUrl.text = [managedObject valueForKey:@"playlistUrl"];
	self.urlString.text = [managedObject valueForKey:@"urlString"];
	self.icyMetaTitleCompliant.on = (NSInteger) [managedObject valueForKey:@"icyMetaTitleCompliant"];
	self.streamType.text = [[managedObject valueForKey:@"streamType"] stringValue];
	self.serverType.text = [[managedObject valueForKey:@"serverType"] stringValue];
	self.contentType.text = [managedObject valueForKey:@"contentType"];
	self.streamDescription.text = [managedObject valueForKey:@"streamDescription"];
	
}

- (void) copyDataToManagedObject {
	[managedObject setValue:[NSNumber numberWithInt:[self.priority.text intValue]] forKey:@"priority"];
	[managedObject setValue:self.playlistUrl.text forKey:@"playlistUrl"];
	[managedObject setValue:self.urlString.text forKey:@"urlString"];
	[managedObject setValue:[NSNumber numberWithBool:self.icyMetaTitleCompliant.on] forKey:@"icyMetaTitleCompliant"];
	[managedObject setValue:[NSNumber numberWithInt:[self.streamType.text intValue]] forKey:@"streamType"];
	[managedObject setValue:[NSNumber numberWithInt:[self.serverType.text intValue]] forKey:@"serverType"];
	[managedObject setValue:self.contentType.text forKey:@"contentType"];
	[managedObject setValue:self.streamDescription.text forKey:@"streamDescription"];
}

- (void) enableEdits:(BOOL) enable {
	
	self.priority.enabled = enable;
	self.playlistUrl.enabled = enable;
	self.urlString.enabled = enable;
	self.icyMetaTitleCompliant.enabled = enable;
	self.streamType.enabled = enable;
	self.serverType.enabled = enable;
	self.contentType.enabled = enable;
	self.streamDescription.enabled = enable;
	
}

@end
