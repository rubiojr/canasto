//
//  FileUploader.m
//  LittleDrop
//
//  Created by Sergio Rubio on 23/05/09.
//  Copyright 2009 CSIC. All rights reserved.
//

#import "NCXFileUploader.h"
#import "DropIO.h"


@implementation NCXFileUploader

@synthesize file;
@synthesize adminToken;
@synthesize dropName;

- (void) main {
	NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
	NSError* error = nil;
	DropIODrop* drop = [DropIO findDropNamed:dropName 
								   withToken:adminToken 
									error:&error];

	NSNotification *n = [NSNotification notificationWithName:@"FileUploaderSendingFile"
													  object: file];
	
	[queue enqueueNotification:n
				  postingStyle: NSPostNow];
	NSData *data = [NSData dataWithContentsOfFile:file];
	DropIODocument* doc = [drop docWithFilename:file
												data: data
											mimeType: @"application/unknown"];
	n = [NSNotification notificationWithName:@"FileUploaderFileSent"
													  object: file];
							
	[queue enqueueNotification:n
				  postingStyle: NSPostNow];
	[doc release];
	[n release];
	[data release];
}
@end
