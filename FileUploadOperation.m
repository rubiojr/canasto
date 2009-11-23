//
//  FileUploader.m
//  LittleDrop
//
//  Created by Sergio Rubio on 23/05/09.
//  Copyright 2009 CSIC. All rights reserved.
//

#import "FileUploadOperation.h"
#import "DropIO.h"


@implementation FileUploadOperation

@synthesize files;
@synthesize adminToken;
@synthesize dropName;

- (void) main {
	NSLog(@"Uploading to drop:");
	NSLog(dropName);
	NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
	NSError* error = nil;
	DropIODrop* drop = [DropIO findDropNamed:dropName 
								   withToken:adminToken 
									error:&error];

	NSNotification *n1 = [NSNotification notificationWithName:@"FileUploaderStarted"
									  object: nil];
	[queue enqueueNotification:n1 postingStyle: NSPostNow];
	
	for (NSString *file in files) { 
		NSLog(@"Sending file");
		NSLog(file);
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
	}
	
	NSNotification *n2 = [NSNotification notificationWithName:@"FileUploaderFinished"
									  object: nil];
	[queue enqueueNotification:n2 postingStyle: NSPostNow];
}
@end
