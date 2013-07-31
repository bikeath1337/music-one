//
//  IniPreferences.h
//  MusicOne
//
//  Created by Bobby Wallace on 02/02/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IniPreferences : NSObject {
	NSMutableDictionary *sections;
}

@property (nonatomic, retain) NSMutableDictionary *sections;

- (id)initWithString: (NSString*) urlString encoding:(NSStringEncoding) encoding;


@end
