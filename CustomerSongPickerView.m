//
//  CustomerSongPickerView.m
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 04/04/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import "CustomerSongPickerView.h"
#import "Song.h"


@implementation CustomerSongPickerView

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section       
{
	NSString * text = [self tableHeader:section];
	if([text length] == 0) {
		return nil;
	}
	
    UILabel *label = [[[UILabel alloc] init] autorelease];
	CGFloat tone = 77.0/255.0;
    label.backgroundColor = [UIColor colorWithRed:tone green:tone blue:tone alpha: 1.0];
	tone = 204.0/255.0;
    label.textColor = [UIColor colorWithRed:tone green:tone blue:tone alpha: 1.0];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize:13.0]; 
	
	label.text = [[self tableHeader:section] uppercaseString];
	
    return label;
}


- (NSString *) tableHeader:(NSInteger) section {
	return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath  
{  
    return 49.05;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellTop0 = @"CellTop";
    static NSString *CellTop1 = @"CellTop1";
    static NSString *CellRecent0 = @"CellRecent";
    static NSString *CellRecent1 = @"CellRecent1";
    static NSString *CellMissed0 = @"CellMissed";
    static NSString *CellMissed1 = @"CellMissed1";
    static NSString *CellFavorite0 = @"CellFavorite";
    static NSString *CellFavorite1 = @"CellFavorite1";
	
    static NSString *CellIdentifier = @"";
		
    UILabel *songLabel = nil, *artistMixLabel = nil, *recentsLabel = nil, *ratingLabel = nil, *numberLabel = nil;
	
	NSManagedObject *managedObject = [fetchedResultsController objectAtIndexPath:indexPath];
	NSInteger rating = -1;
	
	BOOL hasArtistMix = NO;
	
	NSManagedObject * song = managedObject;

	if( tableType == Recent) {
		song = [managedObject valueForKey:@"song"];
	}
	
	hasArtistMix = [[Song getArtistMix:song] length] > 0;
	
	BOOL missed = tableType == Recent && [[managedObject valueForKey:@"missed"] boolValue];
	
    UITableViewCell *cell = nil;
	
	switch (tableType) {
		case Recent:
			if (missed) {
				CellIdentifier = (hasArtistMix) ? CellMissed1 : CellMissed0;
			} else {
				CellIdentifier = (hasArtistMix) ? CellRecent1 : CellRecent0;
			}
			break;
		case Top:
			CellIdentifier = (hasArtistMix) ? CellTop1 : CellTop0;
			break;
		case Favorite:
			CellIdentifier = (hasArtistMix) ? CellFavorite1 : CellFavorite0;
			break;
		default:
			break;
	}
	
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {

		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

		// Common formatting here
		cell.accessoryView = [[UIImageView alloc ] initWithImage:[UIImage imageNamed:@"DetailDisclosure.png"]];
		cell.accessoryView.contentMode = UIViewContentModeCenter;
		CGRect accessoryFrame = cell.accessoryView.frame;
		accessoryFrame.size.height = cell.contentView.frame.size.height;
		accessoryFrame.size.width = 20.0;
		cell.accessoryView.frame = accessoryFrame;
		
		UIImageView * backgroundImageView = [[[UIImageView alloc] initWithFrame:cell.contentView.frame] autorelease];
		backgroundImageView.contentMode = UIViewContentModeTopLeft;
		[cell.contentView addSubview:backgroundImageView];
		
		CGFloat labelwidth = cell.contentView.frame.size.width - cell.accessoryView.frame.size.width - 5.0;
		
		songLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5.0, 5.0, labelwidth, 15.0)] autorelease];
		if(!hasArtistMix) {
			CGRect frame = cell.contentView.frame;
			frame.origin.x += 5.0;
			songLabel.frame = frame;
		}
		songLabel.tag = SONGLABEL_TAG;
		songLabel.font = [UIFont boldSystemFontOfSize:15.0];
		songLabel.textColor = (missed) ? appDelegate.rootViewController.onColor : [UIColor whiteColor]; 
		songLabel.backgroundColor = [UIColor clearColor];
		//songLabel.backgroundColor = [UIColor redColor];
		songLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth; 
		
		[cell.contentView addSubview:songLabel];
		
		if (hasArtistMix) {
			CGRect frame = songLabel.frame;
			frame.origin.y += 20;
			artistMixLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
			artistMixLabel.tag = ARTISTMIXLABEL_TAG; 
			artistMixLabel.font = [UIFont systemFontOfSize:songLabel.font.pointSize]; 
			artistMixLabel.textColor = [UIColor whiteColor];; 
			artistMixLabel.backgroundColor = songLabel.backgroundColor;
			artistMixLabel.autoresizingMask = songLabel.autoresizingMask; 
			
			[cell.contentView addSubview:artistMixLabel];
		} 
		
		if (tableType == Recent) {
			recentsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, cell.contentView.frame.size.height)] autorelease];
			recentsLabel.textAlignment = UITextAlignmentCenter;
			recentsLabel.tag = RECENTSLABEL_TAG; 
			recentsLabel.font = [UIFont systemFontOfSize:13.0]; 
			recentsLabel.textColor = [UIColor whiteColor]; 
			recentsLabel.backgroundColor = appDelegate.rootViewController.onColor;
			recentsLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight; 
			
			CGFloat offset = recentsLabel.frame.size.width + 5.0;
			CGRect songLabelFrame = songLabel.frame;
			
			songLabelFrame.size.width -= offset;
			songLabelFrame.origin.x += offset;
			songLabel.frame = songLabelFrame;
			
			if(artistMixLabel != nil) {
				songLabelFrame.origin.y = artistMixLabel.frame.origin.y;
				artistMixLabel.frame = songLabelFrame;
			}
			
			[cell.contentView addSubview:recentsLabel];
		} else if (tableType == Favorite) {
			rating = [[managedObject valueForKey:@"rating"] integerValue];
			if(rating) {
				ratingLabel = [[[UILabel alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 80.0, 0.0, 80.0, cell.contentView.frame.size.height)] autorelease];
				ratingLabel.textAlignment = UITextAlignmentCenter;
				ratingLabel.tag = RATINGLABEL_TAG; 
				ratingLabel.font = [UIFont systemFontOfSize:16.0]; 
				ratingLabel.textAlignment = UITextAlignmentRight; 
				ratingLabel.textColor = appDelegate.rootViewController.onColor; 
				ratingLabel.backgroundColor = [UIColor clearColor];
				ratingLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight; 
				
				CGRect songLabelFrame = songLabel.frame;
				CGFloat offset = ratingLabel.frame.size.width;
				songLabelFrame.size.width -= offset;
				songLabel.frame = songLabelFrame;
				
				if(artistMixLabel != nil) {
					songLabelFrame.origin.y = artistMixLabel.frame.origin.y;
					artistMixLabel.frame = songLabelFrame;
				}
				
				[cell.contentView addSubview:ratingLabel];
			}
		} else if (tableType == Top) {
			CGRect songLabelFrame = songLabel.frame;
			CGRect frame = songLabelFrame;
			
			frame.size.width = [@"Q0." sizeWithFont:songLabel.font].width + 0.5;
			numberLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
			
			CGFloat offset = frame.size.width + songLabelFrame.origin.x;
			songLabelFrame.size.width -= offset;
			songLabelFrame.origin.x += offset;
			songLabel.frame = songLabelFrame;
			
			if(artistMixLabel != nil) {
				songLabelFrame.origin.y = artistMixLabel.frame.origin.y;
				artistMixLabel.frame = songLabelFrame;
			}
			
			numberLabel.tag = NUMBERLABEL_TAG; 
			numberLabel.font = songLabel.font; 
			numberLabel.textAlignment = UITextAlignmentRight; 
			numberLabel.textColor = songLabel.textColor; 
			numberLabel.backgroundColor = songLabel.backgroundColor;
			numberLabel.autoresizingMask = songLabel.autoresizingMask; 
			
			[cell.contentView addSubview:numberLabel];
		}
    } else {
		
		songLabel = (UILabel *)[cell.contentView viewWithTag:SONGLABEL_TAG];

		if (hasArtistMix) {
			artistMixLabel = (UILabel *)[cell.contentView viewWithTag:ARTISTMIXLABEL_TAG];
		} 
		
		if (tableType == Recent) {
			recentsLabel = (UILabel *)[cell.contentView viewWithTag:RECENTSLABEL_TAG];
		} else if (tableType == Favorite) {
			if(rating) {
				ratingLabel = (UILabel *)[cell.contentView viewWithTag:RATINGLABEL_TAG];
			}
		} else if (tableType == Top) {
			numberLabel = (UILabel *)[cell.contentView viewWithTag:NUMBERLABEL_TAG];
		}
	}

	// Now put values in the cell
	if(tableType == Recent ) {
		recentsLabel.text = [self performSelector:@selector(getRelativeTimeString:) withObject:[managedObject valueForKey:@"timeStamp"]];
	} else {
		if (tableType == Favorite) {
            if (rating < 0)
            {
                rating = [[managedObject valueForKey:@"rating"] integerValue];
            }
			if(rating) {
				ratingLabel.text = [@"★★★★★" substringToIndex:rating];
			}
			
		} else if (tableType == Top) {

			numberLabel.text = [NSString stringWithFormat:@"%d.",[[song valueForKey:@"topSongSequence"] intValue]];
								
		}
		
	}
	
	songLabel.text = [song valueForKey:@"name"]; 
	artistMixLabel.text = [Song getArtistMix:song];

    return cell;
}

@end
