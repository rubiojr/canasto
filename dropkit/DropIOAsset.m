//
//  DropIOAsset.m
//  DropIO
//
//  Created by Chris Patterson on 11/12/08.
//  Copyright 2008 Chris Patterson. All rights reserved.
//

#import "DropIO.h"

#define THUMB_SIZE 32.0

/**
 * The DropIOAsset class is the class that encapsulates the common properties
 * of all Drop.io asset types. It has a reference to its parent {@link DropIODrop}
 * object and knows how to:
 * <ul>
 * <li>update Drop.io with its properties 
 * <li>send itself via email, fax, or to another drop,
 * <li>delete itself from Drop.io.
 * </ul>
 *
 * @see DropIONote
 * @see DropIOImage
 * @see DropIODocument
 * @see DropIOLink
 * @see DropIOMovie
 * @see DropIOAudio
 */
@implementation DropIOAsset

@synthesize properties;
@synthesize drop;

/**
 * Static date formatter for reading and writing UTC-formatted dates in drop properties.
 */
static NSDateFormatter* utcFormatter = nil;

/**
 * Static factory method; returns a new DropIOAsset object with the properties
 * specified in the given dictionary object.
 *
 * @param propDict
 * NSDictionary containing name-value pairs specifying the asset's parameters.
 * See <a href="http://groups.google.com/group/dropio-api/web/full-api-documentation">the Drop.io API documentation</a> for parameter details.
 *
 * @return A new autoreleased DropIOAsset object with the given properties.
 */
+ (DropIOAsset*) assetWithProperties:(NSMutableDictionary*)propDict
{
	DropIOAsset* asset = nil;
	NSString* type = [propDict valueForKey:kDropIOParamKey_Type];
	if ([type isEqualToString:kDropIOAssetType_Note])		asset = [[DropIONote alloc] init];
	else
	if ([type isEqualToString:kDropIOAssetType_Link])		asset = [[DropIOLink alloc] init];
	else
	if ([type isEqualToString:kDropIOAssetType_Document])	asset = [[DropIODocument alloc] init];
	else
	if ([type isEqualToString:kDropIOAssetType_Image])		asset = [[DropIOImage alloc] init];
	else
	if ([type isEqualToString:kDropIOAssetType_Audio])		asset = [[DropIOAudio alloc] init];
	else
	if ([type isEqualToString:kDropIOAssetType_Movie])		asset = [[DropIOMovie alloc] init];
	else
		asset = [[DropIOAsset alloc] init]; // "other" asset type
	
	asset.properties = propDict;
	
	return [asset autorelease];
}

/**
 * Initializes a new, empty asset object.
 *
 * @return A new asset object.
 */
- (id) init
{
	if ((self = [super init]) != nil)
	{
		properties = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}

/**
 * Deallocates memory used by the asset.
 */
- (void) dealloc
{
	[properties release];
	[drop release];
	
	[super dealloc];
}

/**
 * Updates Drop.io with this asset's properties.
 */
- (void) update
{
	[DropIO setLastError:nil];
	
	if (drop != nil)
	{
		// Must already have a valid token to update asset properties; don't include password
		NSString* token = [drop bestTokenIncludingPassword:NO];
		
		NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:8];
		
		// Required parameters
		[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
		[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
		[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
		[params setObject:token								forKey:kDropIOParamKey_Token];
		
		// Optional parameters
		if (self.title != nil)
			[params setObject:self.title
					   forKey:kDropIOParamKey_Title];
		
		if (self.description != nil)
			[params setObject:self.description
					   forKey:kDropIOParamKey_Description];
		
		if ([self.type isEqualToString:kDropIOAssetType_Link])
		{
			if (((DropIOLink*)self).url != nil)
				[params setObject:[((DropIOLink*)self).url absoluteString]
						   forKey:kDropIOParamKey_Url];
		}
		if ([self.type isEqualToString:kDropIOAssetType_Note])
		{
			if (((DropIONote*)self).contents != nil)
				[params setObject:((DropIONote*)self).contents
						   forKey:kDropIOParamKey_Contents];
		}
		
		[drop assetOperation:@"PUT" 
					   atUrl:[NSString stringWithFormat:kDropIOUpdateAssetUrlFormat, drop.name, self.name] 
			  withParameters:params];
	}
}

/**
 * Permanently deletes this asset from its drop on Drop.io.
 * Unless retained elsewhere, this will deallocate the receiver.
 */
- (void) delete
{
	[DropIO setLastError:nil];
	
	if (drop != nil)
	{
		// Must already have a valid token to delete assets; don't include password
		NSString* token = [drop bestTokenIncludingPassword:NO];
		
		NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:4];
		
		// Required parameters
		[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
		[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
		[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
		[params setObject:token								forKey:kDropIOParamKey_Token];
		
		[drop assetOperation:@"DELETE" 
					   atUrl:[NSString stringWithFormat:kDropIOUpdateAssetUrlFormat, drop.name, self.name] 
			  withParameters:params];
		
		if ([DropIO lastError] != nil)
		{
			// For some reason the drop.io API returns a successful deletion in an error response.
			if ([[DropIO lastError] code] == kDropIOErrorCode_AssetDeleted)
			{
				[DropIO setLastError:nil];
				[self setValue:[NSNull null] forKey:kDropIOParamKey_AssetAPIUrl];
				
				DropIODrop* parentDrop = self.drop;
				[parentDrop retain];
				self.drop = nil;
				
				parentDrop.assetCount--;
				
				// might dealloc self... must be last thing we do.
				id aNull = [NSNull null];
				for (NSMutableArray* pageAssets in parentDrop.assetPages)
				{
					if (pageAssets != aNull)
						[pageAssets removeObject:self];
				}
				if (parentDrop.sortedAssets != nil)
					[parentDrop.sortedAssets removeObject:self];
					
				[parentDrop release];
			}
		}
	}
}

/**
 * Sends the asset to a destination specified by the given parameters.
 *
 * @param params
 * NSDictionary containing the API parameters required to send the asset.
 * See <a href="http://groups.google.com/group/dropio-api/web/full-api-documentation">the Drop.io API documentation</a> for parameter details.
 *
 * @see #sendToEmail:message:
 * @see #sendToDropNamed:
 * @see #sendToFax:
 */
- (void) sendWithParameters:(NSDictionary*)params
{
	[drop assetOperation:@"POST" 
				   atUrl:[NSString stringWithFormat:kDropIOSendAssetUrlFormat, drop.name, self.name] 
		  withParameters:params];
	
	if (([DropIO lastError] != nil) && ([[DropIO lastError] code] == kDropIOErrorCode_SendToSuccess))
	{
		[DropIO setLastError:nil];
	}
}

/**
 * Sends the asset via email to the specified email addresses, with the given message text.
 * The asset must already belong to a drop.
 *
 * @param emailAddressArray
 * NSArray of NSStrings containing email addresses to send the asset to.
 *
 * @param optionalMessageText
 * NSString containing the optional body text of the email message. Pass nil to send no message text.
 *
 * @see #sendWithParameters:
 * @see #sendToDropNamed:
 * @see #sendToFax:
 */
- (void) sendToEmail:(NSArray*)emailAddressArray message:(NSString*)optionalMessageText
{
	[DropIO setLastError:nil];
	
	NSMutableString* emailText = [[NSMutableString alloc] init];
	for (NSString* addr in emailAddressArray)
	{
		if ([emailText length] > 0)
			[emailText appendString:@","];
		[emailText appendString:addr];
	}
	
	NSString* token = [drop bestTokenIncludingPassword:YES];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:7];
	
	// Required parameters
	[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	[params setObject:kDropIOParamValue_Medium_Email	forKey:kDropIOParamKey_Medium];
	[params setObject:emailText							forKey:kDropIOParamKey_Emails];
	if (optionalMessageText != nil)
		[params setObject:optionalMessageText			forKey:kDropIOParamKey_Message];
		
	[self sendWithParameters:params];
	
	[emailText release];
}

/**
 * Sends the asset to the drop with the given name. The asset must already belong
 * to an existing drop.
 *
 * @param dropName
 * NSString containing the name of the target drop.
 * The target drop must be configured to allow guests to add assets.
 *
 * @see #sendWithParameters:
 * @see #sendToEmail:message:
 * @see #sendToFax:
 */ 
- (void) sendToDropNamed:(NSString*)dropName
{
	[DropIO setLastError:nil];
	
	NSString* token = [drop bestTokenIncludingPassword:YES];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:6];
	
	// Required parameters
	[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	[params setObject:kDropIOParamValue_Medium_Drop		forKey:kDropIOParamKey_Medium];
	[params setObject:dropName							forKey:kDropIOParamKey_DropName];
	
	[self sendWithParameters:params];
}

/**
 * Sends the asset to the given fax number. Note that currently,
 * the Drop.io API only supports faxing of document and image assets.
 * Also, the asset must already belong to a drop.
 *
 * @param faxNumber
 * NSString containing a fax telephone number.
 *
 * @see #sendWithParameters:
 * @see #sendToEmail:message:
 * @see #sendToDropNamed:
 */ 
- (void) sendToFax:(NSString*)faxNumber
{
	[DropIO setLastError:nil];
	
	NSString* token = [drop bestTokenIncludingPassword:YES];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:6];
	
	// Required parameters
	[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	[params setObject:kDropIOParamValue_Medium_Fax		forKey:kDropIOParamKey_Medium];
	[params setObject:faxNumber							forKey:kDropIOParamKey_FaxNumber];
	
	[self sendWithParameters:params];
}

- (NSString*) name
{
	return [properties valueForKey:@"name"];
}

- (void) setName:(NSString*)value
{
	[properties setValue:value forKey:@"name"];
}

- (NSString*) type
{
	return [properties valueForKey:@"type"];
}

- (void) setType:(NSString*)value
{
	[properties setValue:value forKey:@"type"];
}

- (NSString*) title
{
	return [properties valueForKey:@"title"];
}

- (void) setTitle:(NSString*)value
{
	[properties setValue:value forKey:@"title"];
}

- (NSString*) description
{
	return [properties valueForKey:@"description"];
}

- (void) setDescription:(NSString*)value
{
	[properties setValue:value forKey:@"description"];
}

- (NSNumber*) filesize
{
	NSString* valStr = [properties valueForKey:@"filesize"];
	if (valStr == nil)
		return nil;
	
	return [NSNumber numberWithInteger:[valStr integerValue]];
}

- (void) setFilesize:(NSNumber*)value
{
	[properties setValue:[value stringValue] forKey:@"filesize"];
}

- (NSDate*)   createdAt
{
	NSString* valStr = [properties valueForKey:@"createdAt"];
	if (valStr == nil)
		return nil;
	
	if (utcFormatter == nil)
	{
		utcFormatter = [[NSDateFormatter alloc] init];
		[utcFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss 'UTC'"];
	}
	NSDate* createdAtDate = [utcFormatter dateFromString:valStr];
	
	return createdAtDate;
}

- (void) setCreatedAt:(NSDate*)value
{
	if (utcFormatter == nil)
	{
		utcFormatter = [[NSDateFormatter alloc] init];
		[utcFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss 'UTC'"];
	}
	NSString* strValue = [utcFormatter stringFromDate:value];
	[properties setValue:strValue forKey:@"createdAt"];
}

- (NSString*) status
{
	return [properties valueForKey:@"status"];
}

- (void) setStatus:(NSString*)value
{
	[properties setValue:value forKey:@"status"];
}

- (NSURL*)    hiddenUrl
{
	NSString* valStr = [properties valueForKey:@"hiddenUrl"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setHiddenUrl:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"hiddenUrl"];
}

- (NSImage*) icon
{
	NSString* iconName = [[NSString alloc] initWithFormat:@"%@.png", [self type]];
	NSImage* icon = [NSImage imageNamed:iconName];
	[iconName release];
	return icon;
}

- (void) releaseThumbnail
{
	// abstract method...
}

// Key-Value Coding methods

/**
 * Sets the value for all keys not predefined for this object.
 * Used by Key-Value Coding (KVC) methods. In particular, this
 * method is called by the {@link XMLToObjectParser} class to set
 * values for asset properties not predefined by the DropIOAsset classes.
 * 
 * @param value
 * Object id to set as the value for the given undefined key.
 *
 * @param key
 * NSString containing a key not previously defined for this object.
 */
- (void)setValue:(id)value 
 forUndefinedKey:(NSString *)key 
{	
	[properties setValue:value forKey:key];
}

- (BOOL)isEditable
{
	//if ([drop canEdit] && ([asset isKindOfClass:[DropIONote class]] || [asset isKindOfClass:[DropIOLink class]]))
	return NO;
}

@end

#pragma mark -
#pragma mark DropIOAsset Subclasses
#pragma mark -

/**
 * Encapsulates the properties of a Drop.io note.
 */
@implementation DropIONote

- (NSString*) contents
{
	return [properties valueForKey:@"contents"];
}

- (void) setContents:(NSString*)value
{
	[properties setValue:value forKey:@"contents"];
}

- (BOOL)isEditable
{
	return ((drop != nil) && [drop canEdit]);
}

@end

#pragma mark -

/**
 * Encapsulates the properties of a Drop.io link asset.
 */
@implementation DropIOLink

- (NSURL*) url
{
	NSString* valStr = [properties valueForKey:@"url"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setUrl:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"url"];
}

- (NSImage*) icon
{
	NSString* imageName = nil;
	
	NSString* urlStr = (NSString*)[properties valueForKey:@"url"];
	if (([urlStr rangeOfString:@"http://drop.io/"].location != NSNotFound)
	||  ([urlStr rangeOfString:@"http://www.drop.io/"].location != NSNotFound))
	{
		// For some reason the FAQ drop is not available through the API, 
		// so don't treat it as a drop link.
		if ([urlStr rangeOfString:@"drop.io/faq"].location == NSNotFound) 
			imageName = @"drop.png";
		else
			imageName = @"link.png";
	}
	else
		imageName = @"link.png";
	return [NSImage imageNamed:imageName];
}

- (BOOL)isEditable
{
	return ((drop != nil) && [drop canEdit]);
}

@end

#pragma mark -

/**
 * Encapsulates the properties of a Drop.io image asset.
 */
@implementation DropIOImage

@synthesize thumbImage;

/**
 * Initializes a new, empty image object.
 *
 * @return A new image object.
 */
- (id) init
{
	if ((self = [super init]) != nil)
	{
		thumbImage = nil;
		loadedTarget = nil;
		loadedSel = nil;
	}
	return self;
}

/**
 * Deallocates memory used by the image.
 */
- (void) dealloc
{
	[thumbImage release];
	[super dealloc];
}

- (NSURL*) thumbnail
{
	NSString* valStr = [properties valueForKey:@"thumbnail"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setThumbnail:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"thumbnail"];
}

- (NSURL*) file
{
	NSString* valStr = [properties valueForKey:@"file"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setFile:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"file"];
}

- (NSURL*) converted
{
	NSString* valStr = [properties valueForKey:@"converted"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setConverted:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"converted"];
}

- (NSNumber*) height
{
	NSString* valStr = [properties valueForKey:@"height"];
	if (valStr == nil)
		return nil;
	
	return [NSNumber numberWithInteger:[valStr integerValue]];
}

- (void) setHeight:(NSNumber*)value
{
	[properties setValue:[value stringValue] forKey:@"height"];
}

- (NSNumber*) width
{
	return [NSNumber numberWithInteger:[[properties valueForKey:@"width"] integerValue]];
}

- (void) setWidth:(NSNumber*)value
{
	[properties setValue:[value stringValue] forKey:@"width"];
}

- (void) loadThumbnailImage:(NSURL*)thumbURL
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSData* thumbData = [[NSData alloc] initWithContentsOfURL:thumbURL];
	NSImage* thumbImg = [[NSImage alloc] initWithData:thumbData];
	[thumbData release];
	self.thumbImage = thumbImg;
	[thumbImg release];
	
	[self performSelector:@selector(cropThumbnailImage) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void) cropThumbnailImage
{
	self.thumbImage = [self.thumbImage cropSquare:THUMB_SIZE];
	
	if ((loadedTarget != nil) && (loadedSel != nil))
	{
		if ([loadedTarget respondsToSelector:loadedSel])
			[loadedTarget performSelector:loadedSel];
		
		[loadedTarget release];
		loadedTarget = nil;
		loadedSel = nil;
	}
}

- (NSImage*) icon
{
	NSURL* thumbURL = [self thumbnail];
	if (thumbURL != nil)
	{
		if (thumbImage != nil)
			return thumbImage;
		
		[self performSelectorInBackground:@selector(loadThumbnailImage:) withObject:thumbURL];
	}
		
	return [super icon];
}

- (BOOL) isThumbnailLoaded
{
	return (thumbImage != nil);
}

- (void) whenThumbnailIsLoadedPerformSelector:(SEL)selector target:(id)obj
{
	loadedTarget	= [obj retain];
	loadedSel		= selector;
}

- (void) releaseThumbnail
{
	self.thumbImage = nil;
}

@end

#pragma mark -

/**
 * Encapsulates the properties of a Drop.io document.
 */
@implementation DropIODocument 
- (NSURL*) file
{
	NSString* valStr = [properties valueForKey:@"file"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setFile:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"file"];
}

- (NSURL*) converted
{
	NSString* valStr = [properties valueForKey:@"converted"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setConverted:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"converted"];
}

- (NSNumber*) pages
{
	NSString* valStr = [properties valueForKey:@"pages"];
	if (valStr == nil)
		return nil;
	
	return [NSNumber numberWithInteger:[valStr integerValue]];
}

- (void) setPages:(NSNumber*)value
{
	[properties setValue:[value stringValue] forKey:@"pages"];
}

@end

#pragma mark -

/**
 * Encapsulates the properties of a Drop.io audio asset.
 */
@implementation DropIOAudio 
- (NSURL*) file
{
	NSString* valStr = [properties valueForKey:@"file"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setFile:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"file"];
}

- (NSURL*) converted
{
	NSString* valStr = [properties valueForKey:@"converted"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setConverted:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"converted"];
}

- (NSNumber*) duration
{
	NSString* valStr = [properties valueForKey:@"duration"];
	if (valStr == nil)
		return nil;
	
	return [NSNumber numberWithInteger:[valStr integerValue]];
}

- (void) setDuration:(NSNumber*)value
{
	[properties setValue:[value stringValue] forKey:@"duration"];
}

- (NSString*) artist
{
	return [properties valueForKey:@"artist"];
}

- (void) setArtist:(NSString*)value
{
	[properties setValue:value forKey:@"artist"];
}

- (NSString*) trackTitle
{
	return [properties valueForKey:@"trackTitle"];
}

- (void) setTrackTitle:(NSString*)value
{
	[properties setValue:value forKey:@"trackTitle"];
}

@end

#pragma mark -

/**
 * Encapsulates the properties of a Drop.io movie asset.
 */
@implementation DropIOMovie 

@synthesize thumbImage;

/**
 * Initializes a new, empty movie object.
 *
 * @return A new movie object.
 */
- (id) init
{
	if ((self = [super init]) != nil)
	{
		thumbImage = nil;
		loadedTarget = nil;
		loadedSel = nil;
	}
	return self;
}

- (void) dealloc
{
	[thumbImage release];
	[super dealloc];
}

- (NSURL*) thumbnail
{
	NSString* valStr = [properties valueForKey:@"thumbnail"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setThumbnail:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"thumbnail"];
}

- (NSURL*) file
{
	NSString* valStr = [properties valueForKey:@"file"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setFile:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"file"];
}

- (NSURL*) converted
{
	NSString* valStr = [properties valueForKey:@"converted"];
	if (valStr == nil)
		return nil;
	
	return [NSURL URLWithString:valStr];
}

- (void) setConverted:(NSURL*)value
{
	[properties setValue:[value absoluteString] forKey:@"converted"];
}

- (NSNumber*) duration
{
	NSString* valStr = [properties valueForKey:@"duration"];
	if (valStr == nil)
		return nil;
	
	return [NSNumber numberWithInteger:[valStr integerValue]];
}

- (void) setDuration:(NSNumber*)value
{
	[properties setValue:[value stringValue] forKey:@"duration"];
}

/**
 * Loads the image specified by the asset's {@link #thumbnail} URL into a NSImage object,
 * then calls the {@link #cropThumbnailImage} method on the main thread.
 * Intended to be run in a background thread.
 *
 * @param thumbURL
 * NSURL containing the URL of the thumbnail image for this asset.
 */
- (void) loadThumbnailImage:(NSURL*)thumbURL
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSData* thumbData = [[NSData alloc] initWithContentsOfURL:thumbURL];
	NSImage* thumbImg = [[NSImage alloc] initWithData:thumbData];
	[thumbData release];
	self.thumbImage = thumbImg;
	[thumbImg release];
	
	[self performSelector:@selector(cropThumbnailImage) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
	
	[pool release];
}

/**
 * Crops the asset's thumbnail image into a square, then calls
 * the {@link #loadedSel} selector of the {@link #loadedTarget} object
 * to notify it that the asset's thumbnail has finished loading.
 */
- (void) cropThumbnailImage
{
	self.thumbImage = [self.thumbImage cropSquare:THUMB_SIZE];
	
	if ((loadedTarget != nil) && (loadedSel != nil))
	{
		if ([loadedTarget respondsToSelector:loadedSel])
			[loadedTarget performSelector:loadedSel];
		
		[loadedTarget release];
		loadedTarget = nil;
		loadedSel = nil;
	}
}

- (NSImage*) icon
{
	NSURL* thumbURL = [self thumbnail];
	if (thumbURL != nil)
	{
		if (thumbImage != nil)
			return thumbImage;
		
		[self performSelectorInBackground:@selector(loadThumbnailImage:) withObject:thumbURL];
	}
	
	return [super icon];
}

/**
 * Returns true if the asset's {@link #thumbnail} image has been loaded.
 *
 * @return Boolean true if the thumbnail is loaded.
 */
- (BOOL) isThumbnailLoaded
{
	return (thumbImage != nil);
}

/**
 * Sets up a callback method to be called after the asset's thumbnail image
 * has finished loading. Sets the {@link #loadedTarget} and {@link #loadedSel}
 * properties to be used after the thumbnail is loaded.
 *
 * @param selector
 * A method selector specifying the method to call when the thumbnail is loaded.
 *
 * @param obj
 * Target object id whose selector method is to be called when the thumbnail is loaded.
 */
- (void) whenThumbnailIsLoadedPerformSelector:(SEL)selector target:(id)obj
{
	loadedTarget	= [obj retain];
	loadedSel		= selector;
}

- (void) releaseThumbnail
{
	self.thumbImage = nil;
}

@end
