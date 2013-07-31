//
//  CoreEditingDetailViewDelegate.h
//  MusicOneCoreData
//
//  Created by Bobby Wallace on 02/16/2010.
//  Copyright 2010 Total Managed Fitness. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicPlayerAppDelegate.h"

@protocol CoreEditingDetailViewDelegate;


@interface CoreEditingDetailView : UIViewController  <UINavigationControllerDelegate, UITextFieldDelegate, NSFetchedResultsControllerDelegate> {
	
	NSString * entityName;
	NSArray * sortDescriptors;

	UIBarButtonItem *cancelButton;
	
	BOOL canEdit;
	NSManagedObject *managedObject;
	NSManagedObjectContext *managedObjectContext;
	
	NSPredicate * fetchPredicate;
	NSFetchedResultsController *fetchedResultsController;
	
	id <CoreEditingDetailViewDelegate> detailDelegate;
	
	MusicPlayerAppDelegate * appDelegate;

}

@property (nonatomic, retain) NSString * entityName;
@property (nonatomic, retain) NSArray * sortDescriptors;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSPredicate * fetchPredicate;


@property (nonatomic, retain) UIBarButtonItem *  cancelButton;

@property (nonatomic, assign) NSManagedObject * managedObject;

@property (nonatomic, assign) BOOL canEdit;

@property (nonatomic, assign) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, assign) id <CoreEditingDetailViewDelegate> detailDelegate;
@property (nonatomic, assign) MusicPlayerAppDelegate *appDelegate;

- (BOOL)save;
- (void)cancel;

-(void) processError:(NSError *) error;

- (void) loadDataFromManagedObject;
- (void) copyDataToManagedObject;
- (void) enableEdits:(BOOL) enable;

@end

@protocol CoreEditingDetailViewDelegate
- (void)saved;
//- (void)done;
//- (void)cancel;
@end
