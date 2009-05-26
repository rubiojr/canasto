//
//  XMLToObjectParser.h
//
//  Created by Chris Patterson on 9/1/08.
//  Copyright 2008 Chris Patterson. All rights reserved.
//
//	This source code was adapted from the example code listed at URL:
//	http://blog.atrexis.com/index.cfm/2008/7/28/iPhone--Parse-XML-to-custom-objects
//	That page lists no copyright information for the available source code.
//

#include <AppKit/AppKit.h>

@interface XMLToObjectParser : NSObject 
{
	NSString*				nodeName;				///< Name of the target XML node(s) to be converted to object(s).
	NSString*				className;				///< Name of the Obj-C class to be instantiated for each matched XML node.
	NSMutableArray*			items;					///< Array of objects created from the XML data.
	NSObject*				item;					///< Object being populated during XML parsing; an instance of the given className.
	NSString*				currentNodeName;		///< Name of the current XML node; used during parsing.
	NSMutableString*		currentNodeContent;		///< Mutable string that collects the contents of the current XML node; used during parsing.
	
	NSMutableDictionary*	dropioErrorUserInfo;	///< Dictionary containing Drop.io error properties; used as NSError.userInfo.
	NSError*				dropioError;			///< NSError object describing the Drop.io error, if an error occurs during XML parsing.
}

// Accessors

@property (nonatomic, retain) NSError* dropioError;

- (NSArray *)items;

// Parsing

- (id)parseXMLAtURL:(NSURL *)url 
	   fromNodeName:(NSString *)aNodeName
		   toObject:(NSString *)aClassName 
		 parseError:(NSError **)error;

- (id)parseXMLData:(NSData *)data 
	  fromNodeName:(NSString *)aNodeName
		  toObject:(NSString *)aClassName 
		parseError:(NSError **)error;

@end
