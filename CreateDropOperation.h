//
//  CreateDropOperation.h
//  LittleDrop
//
//  Created by Sergio Rubio on 26/05/09.
//  Copyright 2009 CSIC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DropIO.h>


@interface CreateDropOperation : NSOperation {
  
  NSMutableDictionary *properties;
}

@property(retain) NSMutableDictionary *properties;

@end
