//
//  CreateDropOperation.m
//  LittleDrop
//
//  Created by Sergio Rubio on 26/05/09.
//  Copyright 2009 CSIC. All rights reserved.
//

#import "DeleteAssetOperation.h"


@implementation DeleteAssetOperation

@synthesize  properties;


- (void) main {
	NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
	NSString *assetName = [properties objectForKey:@"assetName"];
	NSString *dropName= [properties objectForKey:@"dropName"];
	NSString *adminToken= [properties objectForKey:@"adminToken"];
  NSLog(@"Properties decoded in DeleteAssetOperation");
	
	NSNotification *n = [NSNotification notificationWithName:@"DeleteAssetOperationStarted"
														  object: assetName];
	[queue enqueueNotification:n postingStyle: NSPostNow];

	NSError* error = nil;
  DropIODrop *drop = [DropIO findDropNamed:dropName withToken:adminToken error:&error];
  //[drop loadAllAssets];

  DropIOAsset *asset = [drop findAssetNamed:assetName loadIfMissing:YES];

  if (asset  != nil) {
    NSLog(@"Asset Found");
    [asset delete];
    NSLog(@"Asset deleted!");
  }

	n = [NSNotification notificationWithName:@"DeleteAssetOperationFinished"
														  object: assetName];
	[queue enqueueNotification:n postingStyle: NSPostNow];
	[n release];
	[queue release];
	[properties release];
	[assetName release];
	[dropName release];
	[adminToken release];
}


@end
