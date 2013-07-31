//
//  IniPreferences.m
//  MusicOne
//
//  Created by Bobby Wallace on 02/02/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "IniPreferences.h"

@interface IniPreferences()
- (void) parse:(NSString *)iniString;
-(NSRange) section:(NSString *) inString;

@end


@implementation IniPreferences

@synthesize sections;

- (id)initWithString: (NSString*) urlString encoding:(NSStringEncoding)encoding{
	[super init];
	NSError *error = nil;
	NSURL *url = [NSURL URLWithString:urlString];
	NSString *playlistString = [NSString stringWithContentsOfURL:url encoding:encoding error:&error];
	if (playlistString == nil || [playlistString length] == 0) {
		return nil;
	}
	//NSLog(@"String=%@", playlistString);
	sections = [[NSMutableDictionary alloc] init];
	[self parse: playlistString];
	
	return self;
															
}

-(void)dealloc {
	[sections release];
	[super dealloc];
}

-(void) parse:(NSString*) iniString {

	NSArray *lines = [[NSArray alloc] initWithArray:[iniString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
	//	NSArray *lines = [iniString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSMutableArray *keys = [[NSMutableArray alloc] init];
	NSMutableArray *values = [[NSMutableArray alloc] init];
	NSString *currentSection = nil;

	for (NSString *rawline in lines){
		if ([rawline length]) {
			NSString *line = [[NSString alloc] initWithString:[rawline stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			NSRange sectionRange = [self section:line];
			if (sectionRange.location != NSNotFound) {
				if (currentSection != nil) {
					NSDictionary *sectionDict = [[NSDictionary alloc] initWithObjects:values forKeys:keys];
					[sections setObject: sectionDict forKey:currentSection];
					[sectionDict release];
				}
				[currentSection release];
				currentSection = [[NSString alloc] initWithString:[[line substringWithRange:sectionRange] lowercaseString]];
				[keys release];
				[values release];
				keys = [[NSMutableArray alloc] init];
				values = [[NSMutableArray alloc] init];
			} else {
				NSMutableArray *pairs = [[NSMutableArray alloc] initWithArray:[line componentsSeparatedByString:@"="]];
				if ([pairs count] == 2) {
					[keys addObject:[[pairs objectAtIndex:0] lowercaseString]];
					[values addObject:[pairs objectAtIndex:1]];
				} else if ([pairs count] > 2) {
					// the line contained more than one "=" so assume that the first "=" delimits the key
					// and the rest of the items the value, so just re-compose that part of the string
					[keys addObject:[[pairs objectAtIndex:0] lowercaseString]];
					NSRange restOfArray = (NSRange) {1, [pairs count]-1}; // drop off key
					[values addObject:[[pairs subarrayWithRange:restOfArray] componentsJoinedByString:@"="]];
				} else { // <= 1
					[keys addObject:[[pairs objectAtIndex:0] lowercaseString]];
					[values addObject:@""];
				}
				[pairs release];
			}
			[line release];
		}
	}

	if (currentSection != nil) {
		NSDictionary *sectionDict = [[NSDictionary alloc] initWithObjects:values forKeys:keys];
		[self.sections setObject: sectionDict forKey:currentSection];
		[sectionDict release];
	}
	
	[lines release];
	[currentSection release];
	[keys release];
	[values release];
	return;

}

-(NSRange) section:(NSString *) inString  {
	
	NSRange sectionStart = [inString rangeOfString:@"["];
	if(sectionStart.location == NSNotFound || sectionStart.location != 0) {
		sectionStart.location = NSNotFound;
		return sectionStart;
	}
	
	NSRange sectionEnd = [inString rangeOfString:@"]"];
	if(sectionEnd.location == NSNotFound ) {
		return sectionEnd;
	}
	
	if (sectionStart.location > sectionEnd.location) {
		sectionStart.location = NSNotFound;
		return sectionStart;
	}
	// get section name with any whitespace trimmed from start and end
	NSString * sectionname = [[NSString alloc] initWithString:[[inString substringWithRange:(NSRange){sectionStart.location+1,sectionEnd.location-1}] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	NSRange result = [inString rangeOfString:sectionname];
	[sectionname release];
	return result;
}

@end
