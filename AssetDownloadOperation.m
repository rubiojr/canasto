//
//  FileUploader.m
//  LittleDrop
//
//  Created by Sergio Rubio on 23/05/09.
//

#import "AssetDownloadOperation.h"
#import "DropIO.h"


@implementation AssetDownloadOperation

@synthesize adminToken;
@synthesize dropName;

- (void) main {
	NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
	NSError* error = nil;
	DropIODrop* drop = [DropIO findDropNamed:dropName 
								   withToken:adminToken 
									   error:&error];
	if (error == nil) {		
		NSNotification *n = [NSNotification notificationWithName:@"AssetDownloaderStarted"
														  object: nil];
		[queue enqueueNotification:n
					  postingStyle: NSPostNow];
		[n release];
		
		NSMutableArray *assets;
		if ([drop countAllAssets] <= 0) {
			NSLog(@"0 Assets found");
			assets = [NSMutableArray arrayWithCapacity:0];
		} else {
			[drop loadAllAssets];
			[drop sortAssets];
			assets = [drop sortedAssets];		
		}
		n = [NSNotification notificationWithName:@"AssetDownloaderFinished"
														  object: assets];	
		[queue enqueueNotification:n
					  postingStyle: NSPostNow];
		[assets release];
		[n release];
	} else {
		NSNotification *n = [NSNotification notificationWithName:@"AssetDownloaderError"
										  object: error];	
		[queue enqueueNotification:n
					  postingStyle: NSPostNow];
		[n release];
	}
}
@end
