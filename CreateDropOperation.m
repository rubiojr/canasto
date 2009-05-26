//
//  CreateDropOperation.m
//  LittleDrop
//
//  Created by Sergio Rubio on 26/05/09.
//  Copyright 2009 CSIC. All rights reserved.
//

#import "CreateDropOperation.h"


@implementation CreateDropOperation

@synthesize  properties;


- (void) main {
	NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
	NSString *password = [properties objectForKey:@"password"];
	NSString *dropName= [properties objectForKey:@"dropName"];
  NSLog(dropName);
	
	NSNotification *n = [NSNotification notificationWithName:@"CreateDropOperationStarted"
														  object: dropName];
	[queue enqueueNotification:n postingStyle: NSPostNow];

  DropIODrop *drop;
	if (password) {
    NSLog(@"Create drop WITH password");
    drop = [DropIO dropWithName:dropName andPassword:password];
	} else {
    NSLog(@"Create drop WITHOUT password");
    drop = [DropIO dropWithName:dropName];
	}
	n = [NSNotification notificationWithName:@"CreateDropOperationFinished"
														  object: drop];
	[queue enqueueNotification:n postingStyle: NSPostNow];
}


@end
