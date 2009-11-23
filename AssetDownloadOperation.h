//
//  FileUploader.h
//  LittleDrop
//
//  Created by Sergio Rubio on 23/05/09.
//  Copyright 2009 CSIC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AssetDownloadOperation : NSOperation {
	NSString * dropName;
	NSString *adminToken;

}

@property(retain) NSString *dropName;
@property(retain) NSString *adminToken;

@end
