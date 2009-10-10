//
//  DeleteAssetOperation.h
//  LittleDrop
//

#import <Cocoa/Cocoa.h>
#import <DropIO.h>


@interface DeleteAssetOperation: NSOperation {
  
  NSMutableDictionary *properties;
}

@property(retain) NSMutableDictionary *properties;

@end
