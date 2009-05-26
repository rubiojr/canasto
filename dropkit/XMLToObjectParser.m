//
//  XMLToObjectParser.m
//
//  Created by Chris Patterson on 9/1/08.
//  Copyright 2008 Chris Patterson. All rights reserved.
//
//	This source code was adapted from the example code listed at URL:
//	http://blog.atrexis.com/index.cfm/2008/7/28/iPhone--Parse-XML-to-custom-objects
//	That page lists no copyright information for the available source code.
//

#import "XMLToObjectParser.h"
#import "DropIO.h"

@implementation XMLToObjectParser

- (NSArray *)items
{
	return items;
}

@synthesize dropioError;

/**
 * Converts the given string to camelCase format.
 * Removes underscores from the input string and capitalizes
 * the character following the underscore.
 *
 * @param aStr
 * NSString to be converted to camelCase format.
 *
 * @return NSString converted to camelCase format.
 */
- (NSString*)camelCaseStringFromString:(NSString*)aStr
{
	NSArray* parts = [aStr componentsSeparatedByString:@"_"];
	
	NSMutableString* result = [[[NSMutableString alloc] init] autorelease];
	
	NSEnumerator* partEnum = [parts objectEnumerator];
	NSString* partStr = [partEnum nextObject];
	[result appendString:partStr];
	while ((partStr = [partEnum nextObject]) != nil)
	{
		[result appendString:[partStr capitalizedString]];
	}
	
	return result;
}

/**
 * Parses the XML document returned from the given URL into an array of instances of the named class. 
 * One instance is created for each XML node that matches the given node name. The named class must
 * define properties whose names match the child XML nodes of the named target XML nodes
 * when converted to "camelCase", or else it must implement setValue:forUndefinedKey:.
 *
 * @param url
 * NSURL of the XML document to be parsed.
 *
 * @param aNodeName
 * NSString containing the name of XML nodes to be matched in the XML document.
 *
 * @param aClassName
 * NSString containing the name of an NSObject subclass that will be instantiated once for
 * each matched XML node in the XML document.
 *
 * @param pError
 * Output parameter pointing to an NSError object on return if any errors occur while loading
 * and parsing the XML document. Pass nil to ignore errors.
 *
 * @return id of the XMLToObjectParser.
 */
- (id)parseXMLAtURL:(NSURL *)url 
	   fromNodeName:(NSString *)aNodeName
		   toObject:(NSString *)aClassName 
		 parseError:(NSError **)pError
{
	NSURLRequest* xmlReq = [[NSURLRequest alloc] initWithURL:url];
	
	// Send the request and get the XML response synchronously (for now).
	NSURLResponse* xmlResp = nil;
	NSData* xmlData = [NSURLConnection sendSynchronousRequest:xmlReq 
											returningResponse:&xmlResp 
														error:pError];
	[xmlReq release];
	
	// xmlResp should be autoreleased, but it leaks in iPhone OS prior to 2.2.
	// Some suggest using the call below to clean up the response object.
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	if ((pError != nil) && ((*pError) != nil))
		return self;
	
	//NSString* xmlStr = [[NSString alloc] initWithData:xmlData encoding:NSASCIIStringEncoding];
	//NSLog(@"Drop.io API raw response data: %@", xmlStr);
	//[xmlStr release];
	
	return [self parseXMLData:xmlData
				 fromNodeName:aNodeName
					 toObject:aClassName
				   parseError:pError];
}

/**
 * Parses the XML contained in the given data object into an array of instances of the named class. 
 * One instance is created for each XML node that matches the given node name. The named class must
 * define properties whose names match the child XML nodes of the named target XML nodes
 * when converted to "camelCase", or else it must implement setValue:forUndefinedKey:.
 *
 * @param data
 * NSData object containing the XML data to be parsed.
 *
 * @param aNodeName
 * NSString containing the name of XML nodes to be matched in the XML data.
 *
 * @param aClassName
 * NSString containing the name of an NSObject subclass that will be instantiated once for
 * each matched XML node in the XML data.
 *
 * @param pError
 * Output parameter pointing to an NSError object on return if any errors occur while loading
 * and parsing the XML data. Pass nil to ignore errors.
 *
 * @return id of the XMLToObjectParser.
 */
- (id)parseXMLData:(NSData *)data 
	   fromNodeName:(NSString *)aNodeName
		   toObject:(NSString *)aClassName 
		 parseError:(NSError **)pError
{
	[items release];
	items = [[NSMutableArray alloc] init];
	
	nodeName  = aNodeName;
	className = aClassName;
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	
	[parser parse];
	
	NSError* parserError = [parser parserError];
	if ((parserError != nil) && (pError != nil))
		*pError = parserError;
	
	if ((dropioErrorUserInfo != nil) && (pError != nil))
	{
		NSString* msgStr	= [dropioErrorUserInfo objectForKey:kDropIOErrorMessage];
		NSString* actionStr	= [dropioErrorUserInfo objectForKey:kDropIOErrorAction];
		NSString* resultStr	= [dropioErrorUserInfo objectForKey:kDropIOErrorResult];
		NSInteger errCode = kDropIOErrorCode_Unknown;
		if (msgStr != nil)
		{
			[dropioErrorUserInfo setObject:msgStr forKey:NSLocalizedFailureReasonErrorKey];
			[dropioErrorUserInfo setObject:msgStr forKey:NSLocalizedDescriptionKey];
			
			// It'd be nice if we didn't rely on string comparisons.
			if ([msgStr isEqualToString:kDropIOErrorMessage_TokenInvalid])
				errCode = kDropIOErrorCode_TokenInvalid;
			else
			if ([msgStr isEqualToString:kDropIOErrorMessage_RateLimitExceeded])
				errCode = kDropIOErrorCode_RateLimitExceeded;
			else
			if ([msgStr isEqualToString:kDropIOErrorMessage_AssetCreationFailed])
				errCode = kDropIOErrorCode_AssetCreationFailed;
			else
			if ([msgStr isEqualToString:kDropIOErrorMessage_AssetDeleted])
				errCode = kDropIOErrorCode_AssetDeleted;
			else
			if ([msgStr isEqualToString:kDropIOErrorMessage_DropDeleted])
				errCode = kDropIOErrorCode_DropDeleted;
		}
		if ([actionStr isEqualToString:@"send_to"] && [resultStr isEqualToString:kDropIOErrorResult_Success])
			errCode = kDropIOErrorCode_SendToSuccess;
		
		*pError = [NSError errorWithDomain:kDropIOErrorDomain code:errCode userInfo:dropioErrorUserInfo];
	}
	
	[parser release];
	
	return self;
}

/**
 * Delegate method that is called when the XML parser encounters the opening tag
 * of a new XML element.
 *
 * @param parser
 * NSXMLParser instance that is currently parsing XML.
 *
 * @param elementName
 * NSString containing the name of the XML element encountered by the parser.
 *
 * @param namespaceURI
 * NSString containing the URI parsed from the namespace declaration for the named XML element.
 *
 * @param qName
 * NSString containing the qualified name of the element.
 *
 * @param attributeDict
 * NSDictionary containing the name-value pairs for the attributes in the XML element.
 */
- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
	attributes:(NSDictionary *)attributeDict
{
	//NSLog(@"Open tag: %@", elementName);
	
	NSString* elName = [self camelCaseStringFromString:elementName];
	
	if([elName isEqualToString:nodeName]) {
		
		if (item != nil)
		{
			NSLog(@"LEAK: existing item: [%@]", item);
			[item release];
		}
		
		// create an instance of a class on run-time
		item = [[NSClassFromString(className) alloc] init];
	}
	else
	if([elName isEqualToString:@"response"]) {
		// create a mutable dictionary to hold drop.io API error response params.
		dropioErrorUserInfo = [[NSMutableDictionary alloc] initWithCapacity:5];
	}
	else {
			//NSLog(@"Allocating currentNodeContent...");
		if (currentNodeName != nil)
		{
			//NSLog(@"LEAK: existing currentNodeName: [%@] (length:%d)", currentNodeName, [currentNodeName length]);
			[currentNodeName release];
		}
		
		if (currentNodeContent != nil)
		{
			//NSLog(@"LEAK: existing currentNodeContent: [%@] (length:%d)", currentNodeContent, [currentNodeContent length]);
			[currentNodeContent release];
		}
		
		currentNodeName = [elName copy];
		currentNodeContent = [[NSMutableString alloc] init];
		
		/*
		if (item != nil) {
			// Handle attributes on elements as keys in the form "elementnameAttrname" for KVC.
			for (id key in attributeDict) {
				id val = [attributeDict objectForKey:key];
				//NSLog(@"attribute: %@, value: %@", key, val);
			
				// Strip namespace from elementName
				NSString* elemKey = elName;
				NSRange colon = [elemKey rangeOfString:@":"];
				if (colon.location != NSNotFound)
					elemKey = [elemKey substringFromIndex:(colon.location+1)];
				
				// use key-value coding
				[item setValue:val forKey:[elemKey stringByAppendingString:[key capitalizedString]]];
			}
		}
		*/
	}
	
	//[elName release];
}

/**
 * Delegate method that is called when the XML parser encounters the closing tag
 * of the current XML element.
 *
 * @param parser
 * NSXMLParser instance that is currently parsing XML.
 *
 * @param elementName
 * NSString containing the name of the XML element last encountered by the parser.
 *
 * @param namespaceURI
 * NSString containing the URI parsed from the namespace declaration for the named XML element.
 *
 * @param qName
 * NSString containing the qualified name of the element.
 */
- (void)parser:(NSXMLParser *)parser 
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
	//NSLog(@"Close tag: %@", elementName);
	
	NSString* elName = [self camelCaseStringFromString:elementName];
	
	if([elName isEqualToString:nodeName]) {
		[items addObject:item];
		
		[item release];
		item = nil;
	}
	else 
	if([elName isEqualToString:currentNodeName]) {
		
		// Strip namespace from elementName
		NSString* elemKey = elName;
		NSRange colon = [elemKey rangeOfString:@":"];
		if (colon.location != NSNotFound)
			elemKey = [elemKey substringFromIndex:(colon.location+1)];
		
		// use key-value coding
		// Protect against element names outside the target item name that match child nodes of the target item.
		// Check for nil item first.
		if (item != nil)
			[item setValue:currentNodeContent forKey:elemKey];
		else
		if (dropioErrorUserInfo != nil)
			[dropioErrorUserInfo setValue:currentNodeContent forKey:elemKey];
		
		//NSLog(@"Releasing currentNodeContent: [%@]", currentNodeContent);
		[currentNodeContent release];
		currentNodeContent = nil;
		
		//NSLog(@"Releasing currentNodeName: [%@]", currentNodeName);
		[currentNodeName release];
		currentNodeName = nil;
	}
	
	//[elName release];
}

/**
 * Delegate method called when the XML parser encounters text data
 * within an XML element. May be called multiple times within one
 * XML element to accumulate the entire text value.
 *
 * @param parser
 * NSXMLParser instance that is currently parsing XML.
 *
 * @param string
 * NSString containing the text data found within an XML element. 
 */
-  (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
	if (currentNodeContent != nil)
		[currentNodeContent appendString:string];
}

/**
 * Delegate method called when the XML parser encounters a CDATA block
 * within an XML element. May be called multiple times within one
 * XML element to accumulate the entire text value.
 *
 * @param parser
 * NSXMLParser instance that is currently parsing XML.
 *
 * @param CDATABlock
 * NSData containing the text data found within an XML element. 
 */
- (void)parser:(NSXMLParser*)parser
	foundCDATA:(NSData*)CDATABlock
{
	if (currentNodeContent != nil)
	{
		NSString* cdataStr = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
		[currentNodeContent appendString:cdataStr];
		[cdataStr release];
	}
}

/**
 * Delegate method called when the XML parser encounters invalid XML.
 *
 * @param parser
 * NSXMLParser instance that is currently parsing XML.
 *
 * @param parseError
 * NSError describing the XML error that occurred.
 */
-     (void)parser:(NSXMLParser *)parser 
parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"XML Parse Error %i: Description: %@, Line: %i, Column: %i", 
		[parseError code],
		[[parser parserError] description], 
		[parser lineNumber],
		[parser columnNumber]);
}

/**
 * Deallocates all memory used by this instance.
 */
- (void)dealloc
{
	[currentNodeContent release];
	[currentNodeName release];
	[dropioErrorUserInfo release];
	[dropioError release];
	[item release];
	[items release];
	[super dealloc];
}

@end