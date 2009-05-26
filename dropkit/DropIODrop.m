//
//  DropIODrop.m
//  DropIO
//
//  Created by Chris Patterson on 11/10/08.
//  Copyright 2008 Chris Patterson. All rights reserved.
//

#import "DropIO.h"
#import "DropIODrop.h"

/**
 * Class that encapsulates a Drop.io drop.
 * Drops have properties and a list of assets.
 */
@implementation DropIODrop

@synthesize name;
@synthesize password;

@synthesize adminPassword;
@synthesize guestPassword;
@synthesize adminToken;
@synthesize guestToken;

@synthesize email;
@synthesize voicemail;
@synthesize conference;

@synthesize rss;
@synthesize fax;
@synthesize hiddenUploadUrl;

@synthesize expirationLength;
@synthesize currentBytes;
@synthesize maxBytes;

@synthesize assetCount;

@synthesize guestsCanAdd;
@synthesize guestsCanDelete;
@synthesize guestsCanComment;

@synthesize premiumCode;

@synthesize assetPages;

@synthesize title;
@synthesize sortOrder;
@synthesize sortedAssets;
@synthesize sortedPageIndexes;

@synthesize loadingAssets;

/**
 * Initialize a DropIODrop instance.
 *
 * @return id of the instance.
 */
- (id) init
{
	if ((self = [super init]) != nil)
	{
		sortOrder = AssetSortOrder_API;
	}
	return self;
}

/**
 * Deallocates memory used by the drop object.
 */
- (void) dealloc
{
	[self unloadAllAssets];
	
	[name release];
	[password release];
	[adminPassword release];
	[guestPassword release];
	[adminToken release];
	[guestToken release];
	
	[email release];
	[voicemail release];
	[conference release];
	
	[rss release];
	[fax release];
	[hiddenUploadUrl release];
	
	[expirationLength release];
	
	[premiumCode release];
	
	[title release];

	[super dealloc];
}

#pragma mark -
#pragma mark Accessors returning properties as NSURLs
#pragma mark -

/**
 * Returns a "mailto:" URL for the drop's email address.
 * 
 * @return An autoreleased NSURL object containing the drop's email address.
 */
- (NSURL*) emailURL
{
	if (email == nil)
		return nil;
	
	return [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", email]];
}

/**
 * Returns a "tel:" URL for the drop's voicemail phone number.
 * Within the iPhone SDK, passing this URL to the UIApplication openURL: method
 * will launch the Phone app and dial the drop's voicemail number.
 * 
 * @return An autoreleased NSURL object containing the drop's voicemail phone number.
 */
- (NSURL*) voicemailURL
{
	if (voicemail == nil)
		return nil;
	NSString* voicemailUrlStr = [voicemail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	voicemailUrlStr = [NSString stringWithFormat:@"tel:+1-%@", voicemailUrlStr];
	voicemailUrlStr = [voicemailUrlStr stringByReplacingOccurrencesOfString:@" x " withString:@","];
		
	return [NSURL URLWithString:voicemailUrlStr];
}

/**
 * Returns a "tel:" URL for the drop's conference phone number.
 * Within the iPhone SDK, passing this URL to the UIApplication openURL: method
 * will launch the Phone app and dial the drop's conference number.
 * 
 * @return An autoreleased NSURL object containing the drop's conference phone number.
 */
- (NSURL*) conferenceURL
{
	if (conference == nil)
		return nil;
	
	NSString* conferenceUrlStr = [conference stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	conferenceUrlStr = [NSString stringWithFormat:@"tel:+1-%@", conferenceUrlStr];
	conferenceUrlStr = [conferenceUrlStr stringByReplacingOccurrencesOfString:@" x " withString:@","];
	
	return [NSURL URLWithString:conferenceUrlStr];
}

/**
 * Returns the drop's RSS feed URL.
 *
 * @return An autoreleased NSURL object pointing to the drop's RSS feed.
 */
- (NSURL*) rssURL
{
	if (rss == nil)
		return nil;
	
	return [NSURL URLWithString:rss];
}

/**
 * Returns the URL of the drop's fax cover page document.
 *
 * @return An autoreleased NSURL object pointing to the drop's fax cover page.
 */
- (NSURL*) faxURL
{
	if (fax == nil)
		return nil;
	
	return [NSURL URLWithString:fax];
}

/**
 * Returns the URL of the drop's hidden upload URL.
 * The hidden upload URL is a URL that does not reveal the drop's name.
 *
 * @return An autoreleased NSURL object pointing to the drop's hidden upload URL.
 */
- (NSURL*) hiddenUploadURL
{
	if (hiddenUploadUrl == nil)
		return nil;
	
	return [NSURL URLWithString:hiddenUploadUrl];
}

/**
 * Returns the drop's RSS feed URL as a dropcast URL (using the "itpc:" protocol).
 *
 * @return An autoreleased NSURL object pointing to the drop's dropcast URL.
 */
- (NSURL*) dropcastURL
{
	// returns an "itpc:" URL from the rss URL.
	if (rss == nil)
		return nil;
	
	// Convert RSS url in format: "http://drop.io/path/dropName.rss"
	// to dropcast url in format: "itpc://drop.io/path/dropName/podcast.rss"
	NSString* dropcast = [[rss stringByReplacingOccurrencesOfString:@"http://" 
														 withString:@"itpc://"]
							   stringByReplacingOccurrencesOfString:@".rss"
														 withString:@"/podcast.rss"];
	
	return [NSURL URLWithString:dropcast];
}

/**
 * Returns the drop's RSS feed URL in the given format.
 *
 * @param format
 * DropFeedFormat specifier; either kDropFeedFormat_RSS or kDropFeedFormat_Dropcast.
 *
 * @return An autoreleased NSURL pointing to the drop's RSS feed URL.
 */
- (NSURL*) feedURLForFormat:(DropFeedFormat)format
{
	switch (format)
	{
		case kDropFeedFormat_RSS:
			return [self rssURL];
		
		case kDropFeedFormat_Dropcast:
			return [self dropcastURL];
			
		default:
			break;
	}
	
	return nil;
}

/**
 * Returns the drop's API URL.
 *
 * @return An autoreleased NSURL object pointing to the drop's API URL.
 */
- (NSURL*) apiURL
{
	NSString* token = [self bestTokenIncludingPassword:YES];
	
	return [DropIO URLForDropNamed:name withToken:token];
}

/**
 * Returns the drop's web URL.
 *
 * @return An autoreleased NSURL object pointing to the drop's web URL.
 */
- (NSURL*) dropURL
{
	NSString* dropUrlStr = [NSString stringWithFormat:kDropIODropWebUrlFormat, [self name]];
	return [NSURL URLWithString:dropUrlStr];
}

/**
 * Returns the drop's mobile API URL.
 *
 * @return An autoreleased NSURL object pointing to the drop's mobile web URL.
 */
- (NSURL*) mobileURL
{
	NSString* dropUrlStr = [NSString stringWithFormat:kDropIODropMobileUrlFormat, [self name]];
	return [NSURL URLWithString:dropUrlStr];
}

/**
 * Returns the drop's chat URL.
 *
 * @return An autoreleased NSURL object pointing to the drop's web chat URL.
 */
- (NSURL*) chatURL
{
	NSString* dropUrlStr = [NSString stringWithFormat:kDropIODropChatUrlFormat, [self name]];
	return [NSURL URLWithString:dropUrlStr];
}

/**
 * Returns the drop's URL for a web authentication redirect, which can be used to pre-authenticate
 * a web view of the drop so that the user does not need to re-enter their security token.
 * See <a href=""></a> for more information.
 *
 * @return An autoreleased NSURL object pointing to the drop's web authentication URL.
 */
- (NSURL*) webAuthURL
{
	NSString* webUrlStr = [NSString stringWithFormat:kDropIODropWebAuthUrlFormat, [self name]];
	return [NSURL URLWithString:webUrlStr];
}

#pragma mark -
#pragma mark Asset URLs
#pragma mark -

/**
 * Returns the URL for the drop's list of assets on the given page.
 * The Drop.io API returns the list of assets in a drop in pages of 30 assets per page.
 *
 * @param assetsPage
 * Integer one-based page number to return a list of assets for.
 *
 * @return An autoreleased NSURL object pointing to the given page of assets in the drop.
 */ 
- (NSURL*) URLForAssetsPage:(NSUInteger)assetsPage
{
	// Returns a URL in the form:
	// "http://api.drop.io/drops/" + dropname + "/assets?api_key=" + apikey + "&version=1.0&token=" + admin_or_guest_token + "&page=" + page
	// API returns 30 assets per page. To get all assets, call this method incrementing page until number of assets equals drop.assetCount.

	if (![DropIO checkAPIKey])
		return nil;
	
	NSString* token = [self bestTokenIncludingPassword:YES];
	
	NSString* urlStr = [[NSString alloc] initWithFormat:kDropIOAssetsUrlFormat, 
						name, 
						kDropIOParamKey_APIKey,  [DropIO APIKey], 
						kDropIOParamKey_Version, kDropIOParamValue_Version_Latest,
						kDropIOParamKey_Format,  kDropIOParamValue_Format_XML,
						kDropIOParamKey_Token,   token, 
						kDropIOParamKey_Page,    assetsPage];
	NSURL* assetsPageURL = [NSURL URLWithString:urlStr];
	[urlStr release];
	return assetsPageURL;
}

/**
 * Returns the Drop.io API URL for the asset with the given name in this drop.
 *
 * @param assetName
 * NSString containing the name of the asset whose URL is to be returned.
 *
 * @return An autoreleased NSURL object pointing to the named asset in this drop.
 */
- (NSURL*) URLForAssetNamed:(NSString*)assetName
{
	// Returns a URL in the form:
	// "http://api.drop.io/drops/" + dropName + "/assets/" + assetName + ?api_key=" + apikey + "&version=1.0&token=" + admin_or_guest_token
	
	if (![DropIO checkAPIKey])
		return nil;
	
	NSString* token = [self bestTokenIncludingPassword:YES];
	
	NSString* urlStr = [[NSString alloc] initWithFormat:kDropIOAssetUrlFormat, 
						name, 
						assetName, 
						kDropIOParamKey_APIKey,  [DropIO APIKey], 
						kDropIOParamKey_Version, kDropIOParamValue_Version_Latest,
						kDropIOParamKey_Format,  kDropIOParamValue_Format_XML,
						kDropIOParamKey_Token,   token];
	NSURL* assetURL = [NSURL URLWithString:urlStr];
	[urlStr release];
	
	return assetURL;
}

#pragma mark -
#pragma mark Getting NSIndexSets and asset page indexes
#pragma mark -

/**
 * Returns the index of the last asset page for this drop.
 * The index is calculated from the {@link #assetCount} property of the drop object.
 *
 * @return An unsigned integer representing the zero-based index of the last asset page for the drop.
 */
- (NSUInteger) lastAssetPageIndex
{
	NSUInteger totalPages  = assetCount / kAssetsPerPage;
	if (assetCount % kAssetsPerPage > 0)
		totalPages++;
	
	return totalPages; // one-based index
}

- (NSIndexSet*) indexSetForAllAssetPages
{
	return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [self lastAssetPageIndex])];
}

#pragma mark -
#pragma mark Loading Assets
#pragma mark -

/**
 * Wrapper method intended to be run on a background thread, which calls the given selector of this object. 
 * The {@link #loadingAssets} flag is checked to make sure only one background thread per drop object is running at once.
 *
 * @param loadSelector
 * Selector for the method to be executed on the background thread.
 *
 * @param object
 * id of a parameter object to be passed to the method specified by the selector.
 */
- (void) bgLoad:(SEL)loadSelector withObject:(id)object
{
	if (self.loadingAssets == YES)
		return;
	self.loadingAssets = YES;
	
	NSAutoreleasePool* loadPool = [[NSAutoreleasePool alloc] init];
	[self performSelector:loadSelector withObject:object];
	[loadPool release];
	
	self.loadingAssets = NO;
}

/**
 * Loads all assets in the asset pages specified by the given page indexes.
 *
 * @param pageIndexes
 * An NSIndexSet object specifying the range of asset page indexes to be loaded.
 *
 * @see #loadAllAssets
 * @see #loadAssetPagesInBackground:
 */
- (void) loadAssetPages:(NSIndexSet*)pageIndexes
{
	if (![DropIO checkAPIKey])
		return;
	
	NSUInteger firstPage = [pageIndexes firstIndex];
	NSUInteger lastPage  = [pageIndexes lastIndex];
	if (firstPage == NSNotFound)
		return;
	
	NSUInteger page = 0;
	id aNull = [NSNull null];
	
	if (self.assetPages == nil)
	{
		NSUInteger totalPages = [self lastAssetPageIndex];
		NSMutableArray* newAssetPages = [[NSMutableArray alloc] initWithCapacity:totalPages];
		for (page = 0; page < totalPages; page++)
			[newAssetPages insertObject:aNull atIndex:page];
		self.assetPages = newAssetPages;
		[newAssetPages release];
	}
	
	NSLog(@"Loading assets from page %d to page %d for drop: %@", firstPage, lastPage, [self name]);
	
	NSUInteger loadedAssetCount = 0;
	for (page = firstPage; page <= lastPage; page++)
	{
		NSMutableArray* pageAssets = [self.assetPages objectAtIndex:page-1];
		if (pageAssets == aNull)
		{
			pageAssets = [[NSMutableArray alloc] initWithCapacity:kAssetsPerPage];
			[self.assetPages insertObject:pageAssets atIndex:page-1];
			[pageAssets release];
		}
		
		NSError* error = nil;
		NSArray* props = [DropIO parseResponseFromURL:[self URLForAssetsPage:page]
										 fromNodeName:@"asset"
											 toObject:@"NSMutableDictionary"
										   parseError:&error];
		if ((props != nil) && ([props count] > 0))
		{
			NSUInteger assetIndex = 0;
			for (NSMutableDictionary* propDict in props)
			{
				DropIOAsset* asset = [DropIOAsset assetWithProperties:propDict];
				[asset setDrop:self];
				[asset setValue:[[self URLForAssetNamed:[asset name]] absoluteString] forKey:kDropIOParamKey_AssetAPIUrl];
				
				// Replace (and release) asset if it was already loaded before, thus refreshing it.
				[pageAssets insertObject:asset atIndex:assetIndex++];
				
				// Increment total counter
				loadedAssetCount++;
			}
		}
		else
			break; // Stop sending asset page requests if an error occurs
	}
	
	NSLog(@"Loaded %d assets for drop: %@", loadedAssetCount, [self name]);
}

/**
 * Loads all assets in the asset pages specified by the given page indexes, in a background thread.
 *
 * @param pageIndexes
 * An NSIndexSet object specifying the range of asset page indexes to be loaded.
 *
 * @see #loadAllAssets
 * @see #loadAssetPages:
 */
- (void) loadAssetPagesInBackground:(NSIndexSet*)pageIndexes
{
	[self bgLoad:@selector(loadAssetPages:) withObject:pageIndexes];
}

/**
 * Loads all assets in the drop. If the drop has too many assets to load all at once
 * (as determined by the {@link #canLoadAllAssets} method), the assets are not loaded
 * and an error message is logged.
 *
 * @see #loadAssetPages:
 * @see #loadAssetPagesInBackground:
 * @see #loadAllAssetsInBackground
 */
- (void) loadAllAssets
{
	if (![self canLoadAllAssets])
	{
		NSLog(@"ERROR: Attempt to load all %d assets for drop: %@", assetCount, [self name]);
		return;
	}
	
	[self loadAssetPages:[self indexSetForAllAssetPages]];
}

/**
 * Loads all assets in the drop, in a background thread. If the drop has too many assets to load all at once
 * (as determined by the {@link #canLoadAllAssets} method), the assets are not loaded
 * and an error message is logged.
 *
 * @see #loadAssetPages:
 * @see #loadAssetPagesInBackground:
 * @see #loadAllAssets
 */
- (void) loadAllAssetsInBackground
{
	[self bgLoad:@selector(loadAllAssets) withObject:nil];
}

#pragma mark -
#pragma mark Unloading Assets
#pragma mark -

/**
 * Unloads all assets in the asset pages specified by the given page indexes.
 *
 * @param pageIndexes
 * An NSIndexSet object specifying the range of asset page indexes to be unloaded from memory.
 *
 * @see #unloadAllAssets
 */
- (void) unloadAssetPages:(NSIndexSet*)pageIndexes
{
	NSUInteger firstPage = [pageIndexes firstIndex];
	NSUInteger lastPage  = [pageIndexes lastIndex];
	NSUInteger page;
	
	if (firstPage == NSNotFound)
		return;
	
	id aNull = [NSNull null];
	
	
	for (page = firstPage; page <= lastPage; page++)
	{
		// Release assets array at the page index.
		[self.assetPages insertObject:aNull atIndex:page-1];
	}
	self.sortedAssets = nil;
	self.sortedPageIndexes = nil;
}

/**
 * Unloads all assets in the drop.
 *
 * @see #unloadAssetPages:
 */
- (void) unloadAllAssets
{
	self.assetPages = nil;
	self.sortedAssets = nil;
	self.sortedPageIndexes = nil;
}

#pragma mark -
#pragma mark Reloading Assets
#pragma mark -

/**
 * Reloads all assets in the asset pages specified by the given page indexes.
 *
 * @param pageIndexes
 * An NSIndexSet object specifying the range of asset page indexes to be loaded.
 *
 * @see #reloadAllAssets
 * @see #reloadAssetPagesInBackground:
 */
- (void) reloadAssetPages:(NSIndexSet*)pageIndexes
{
	[self unloadAssetPages:pageIndexes];
	[self loadAssetPages:pageIndexes];
}

/**
 * Reloads all assets in the asset pages specified by the given page indexes, in a background thread.
 *
 * @param pageIndexes
 * An NSIndexSet object specifying the range of asset page indexes to be loaded.
 *
 * @see #reloadAllAssets
 * @see #reloadAssetPages:
 */
- (void) reloadAssetPagesInBackground:(NSIndexSet*)pageIndexes
{
	[self bgLoad:@selector(reloadAssetPages:) withObject:pageIndexes];
}

/**
 * Reloads all assets in the drop.
 *
 * @see #reloadAllAssetsInBackground
 * @see #reloadAssetPages:
 * @see #reloadAssetPagesInBackground:
 */
- (void) reloadAllAssets
{
	[self unloadAllAssets];
	[self loadAllAssets];
}

/**
 * Reloads all assets in the drop, in a background thread.
 *
 * @see #reloadAllAssets
 * @see #reloadAssetPages:
 * @see #reloadAssetPagesInBackground:
 */
- (void) reloadAllAssetsInBackground
{
	[self bgLoad:@selector(reloadAllAssets) withObject:nil];
}

#pragma mark -
#pragma mark Checking for Loaded Assets
#pragma mark -

/**
 * Returns true if the {@link DropIOAsset} objects in the given asset pages have been loaded.
 *
 * @return Boolean true if all {@link #assetPages} arrays have been loaded.
 */
- (BOOL) areAssetPagesLoaded:(NSIndexSet*)pageIndexes
{
	NSUInteger page;
	if (self.assetPages == nil)
		return NO;
	
	NSUInteger firstPage = [pageIndexes firstIndex];
	NSUInteger lastPage  = [pageIndexes lastIndex];
	if (firstPage == NSNotFound)
		return YES;
	
	id aNull = [NSNull null];
	
	for (page = firstPage; page <= lastPage; page++)
	{
		if ([self.assetPages objectAtIndex:page-1] == aNull)
			return NO;
	}
	
	return YES;
}

/**
 * Returns true if all of the drop's {@link DropIOAsset} objects have been loaded.
 *
 * @return Boolean true if all {@link #assetPages} arrays have been loaded.
 */
- (BOOL) areAllAssetsLoaded
{
	return [self areAssetPagesLoaded:[self indexSetForAllAssetPages]];
}

#pragma mark -
#pragma mark Finding Assets
#pragma mark -

/**
 * Finds a {@link DropIOAsset} object with the given name within the given asset pages.
 * If not found in the {@link #assetPages} array, the object is loaded from Drop.io
 * if <i>loadFlag</i> is set.
 *
 * @param assetName
 * NSString containing the name of the asset to find in this drop.
 *
 * @param loadFlag
 * Boolean flag indicating that the {@link DropIOAsset} object should be loaded 
 * from Drop.io if it is not already loaded.
 *
 * @return An autoreleased {@link DropIOAsset} object with the given name.
 */
- (DropIOAsset*) findAssetNamed:(NSString*)assetName inAssetPages:(NSIndexSet*)pageIndexes loadIfMissing:(BOOL)loadFlag
{
	DropIOAsset* foundAsset = nil;
	NSUInteger page;
	
	id aNull = [NSNull null];
	
	if (self.assetPages != nil)
	{
		NSUInteger firstPage = [pageIndexes firstIndex];
		NSUInteger lastPage  = [pageIndexes lastIndex];
		
		if (firstPage != NSNotFound)
		{
			for (page = firstPage; page <= lastPage; page++)
			{
				NSMutableArray* pageAssets = [self.assetPages objectAtIndex:page-1];
				if (pageAssets != aNull)
				{
					for (DropIOAsset* thisAsset in pageAssets)
					{
						if ((thisAsset != nil) && [[thisAsset name] isEqualToString:assetName])
						{
							foundAsset = thisAsset;
							break;
						}
					}
				}
			}
		}
	}
	
	if ((foundAsset == nil) && loadFlag)
	{
		[self loadAssetPages:pageIndexes];
		foundAsset = [self findAssetNamed:assetName inAssetPages:pageIndexes loadIfMissing:NO];
	}
	
	return foundAsset;
}

/**
 * Finds a {@link DropIOAsset} object in this drop with the given name.
 * If not found in the {@link #assetPages} array, the object is loaded from Drop.io
 * if <i>loadFlag</i> is set.
 *
 * @param assetName
 * NSString containing the name of the asset to find in this drop.
 *
 * @param loadFlag
 * Boolean flag indicating that the {@link DropIOAsset} object should be loaded 
 * from Drop.io if it is not already loaded.
 *
 * @return An autoreleased {@link DropIOAsset} object with the given name.
 */
- (DropIOAsset*) findAssetNamed:(NSString*)assetName loadAllIfMissing:(BOOL)loadFlag
{
	NSIndexSet* allPages = [self indexSetForAllAssetPages];
	return [self findAssetNamed:assetName inAssetPages:allPages loadIfMissing:loadFlag];
}

/**
 * Returns the {@link DropIOAsset} object at the given index in the drop's {@link #assets} array.
 *
 * @param index
 * Integer index of the desired asset in this drop.
 *
 * @return The autoreleased {@link DropIOAsset} object at the given index.
 */
- (DropIOAsset*) assetAtIndex:(NSUInteger)index inAssetPages:(NSIndexSet*)pageIndexes
{
	DropIOAsset* foundAsset = nil;
	
	if (self.assetPages == nil)
		[self loadAssetPages:pageIndexes];
	
	NSUInteger firstPage = [pageIndexes firstIndex];
	NSUInteger lastPage  = [pageIndexes lastIndex];
	NSUInteger page;
	if (firstPage != NSNotFound)
	{
		id aNull = [NSNull null];
		if ([self.assetPages objectAtIndex:firstPage-1] == aNull)
			[self loadAssetPages:pageIndexes];
		
		if (sortOrder == AssetSortOrder_API)
		{
			NSUInteger assetIndex = 0;
			for (page = firstPage; page <= lastPage; page++)
			{
				NSMutableArray* pageAssets = [self.assetPages objectAtIndex:page-1];
				if (pageAssets != aNull)
				{
					for (DropIOAsset* thisAsset in pageAssets)
					{
						if ((thisAsset != nil) && (index == assetIndex++))
						{
							foundAsset = thisAsset;
							break;
						}
					}
				}
			}
		}
		else
		{
			if (sortedAssets == nil || ![pageIndexes isEqualToIndexSet:sortedPageIndexes])
				[self sortAssetPages:pageIndexes];
			if (index < [sortedAssets count])
				foundAsset = [sortedAssets objectAtIndex:index];
		}
	}
	return foundAsset;
}

#pragma mark -
#pragma mark Sorting Assets
#pragma mark -

/**
 * Sorts the two given assets by title.
 *
 * @param firstAsset
 * First DropIOAsset object id to compare.
 *
 * @param secondAsset
 * Second DropIOAsset object id to compare.
 *
 * @param context
 * Untyped void* pointer to user-supplied data structure. Not used.
 *
 * @return NSComparisonResult indicating which asset should sort first.
 */
NSComparisonResult sortAssetsByTitle(id firstAsset, id secondAsset, void* context)
{
	return [[[firstAsset title] lowercaseString] compare:[[secondAsset title] lowercaseString]];
}

/**
 * Sorts the two given assets by creation date.
 *
 * @param firstAsset
 * First DropIOAsset object id to compare.
 *
 * @param secondAsset
 * Second DropIOAsset object id to compare.
 *
 * @param context
 * Untyped void* pointer to user-supplied data structure. Not used.
 *
 * @return NSComparisonResult indicating which asset should sort first.
 */
NSComparisonResult sortAssetsByDate(id firstAsset, id secondAsset, void* context)
{
	return [[secondAsset createdAt] compare:[firstAsset createdAt]];
}

/**
 * Sorts the two given assets by type, then title.
 *
 * @param firstAsset
 * First DropIOAsset object id to compare.
 *
 * @param secondAsset
 * Second DropIOAsset object id to compare.
 *
 * @param context
 * Untyped void* pointer to user-supplied data structure. Not used.
 *
 * @return NSComparisonResult indicating which asset should sort first.
 */
NSComparisonResult sortAssetsByType(id firstAsset, id secondAsset, void* context)
{
	NSComparisonResult result = [[firstAsset type] compare:[secondAsset type]];
	if (result == NSOrderedSame)
		result = sortAssetsByTitle(firstAsset, secondAsset, context);
	return result;
}

/**
 * Sorts the assets within the given asset pages according to the drop's {@link #sortOrder} setting.
 *
 * @param pageIndexes
 * NSIndexSet specifying the range of asset pages over which to sort assets.
 */
- (void) sortAssetPages:(NSIndexSet*)pageIndexes
{
	NSAutoreleasePool* sortPool = [[NSAutoreleasePool alloc] init];
	NSUInteger firstPage = [pageIndexes firstIndex];
	NSUInteger lastPage  = [pageIndexes lastIndex];
	if (firstPage != NSNotFound)
	{
		id aNull = [NSNull null];
		NSMutableArray* sortArray = [[NSMutableArray alloc] initWithCapacity:((lastPage - firstPage)*kAssetsPerPage)];
		NSUInteger page;
		for (page = firstPage; page <= lastPage; page++)
		{
			NSMutableArray* pageAssets = [self.assetPages objectAtIndex:page-1];
			if (pageAssets != aNull)
				[sortArray addObjectsFromArray:pageAssets];
		}
		
		NSInteger (*compareFunc)(id, id, void *) = nil;
		switch (sortOrder)
		{
			case AssetSortOrder_Date:	compareFunc = sortAssetsByDate; break;
			case AssetSortOrder_Type:	compareFunc = sortAssetsByType; break;
			case AssetSortOrder_Title:	compareFunc = sortAssetsByTitle;break;
			default:					compareFunc = sortAssetsByType; break;
		}
		[sortArray sortUsingFunction:compareFunc context:nil];
		self.sortedAssets = sortArray;
		[sortArray release];
		self.sortedPageIndexes = pageIndexes;
	}
	[sortPool release];
}

/**
 * Sorts all the drop's assets according to the drop's {@link #sortOrder} setting.
 */
- (void) sortAllAssets
{
	[self sortAssetPages:[self indexSetForAllAssetPages]];
}

#pragma mark -
#pragma mark Counting Assets
#pragma mark -

/**
 * Returns an integer count of all assets within the given asset pages.
 *
 * @param pageIndexes
 * NSIndexSet specifying the range of asset pages over which to count assets.
 *
 * @return Unsigned integer count of all assets within the given asset pages.
 */
- (NSUInteger) countAssetsInAssetPages:(NSIndexSet*)pageIndexes
{
	NSUInteger numAssets = 0;
	if (pageIndexes == nil)
		return numAssets;
	
	NSUInteger firstPage = [pageIndexes firstIndex];
	NSUInteger lastPage  = [pageIndexes lastIndex];
	NSUInteger page;
	if (firstPage != NSNotFound)
	{
		for (page = firstPage; page < lastPage; page++)
			numAssets += kAssetsPerPage;
		
		// Get remainder for last page
		if (lastPage == [self lastAssetPageIndex])
		{
			NSUInteger remainder = assetCount % kAssetsPerPage;
			if (remainder > 0)
				numAssets += remainder;
			else
				numAssets += kAssetsPerPage;
		}
		else
			numAssets += kAssetsPerPage;
	}
	return numAssets;
}

/**
 * Returns an integer count of the {@link DropIOAsset}s in this drop.
 *
 * @return Integer count of the number of assets in this drop.
 */
- (NSUInteger) countAllAssets
{
	return self.assetCount;
}

/**
 * Returns an integer count of the {@link DropIOAsset}s of the given type within the given asset pages.
 *
 * @param assetType
 * NSString containing the type of asset to be counted. Must be one of the kDropIOAssetType_* constants
 * defined in DropIOAsset.h.
 *
 * @param pageIndexes
 * NSIndexSet specifying the range of asset pages over which to count assets.
 *
 * @return Integer count of the number of assets of the given type within the asset page range.
 */
- (NSUInteger) countAssetsOfType:(NSString*)assetType inAssetPages:(NSIndexSet*)pageIndexes
{
	NSUInteger count = 0;
	if (self.assetPages != nil)
	{
		NSUInteger firstPage = [pageIndexes firstIndex];
		NSUInteger lastPage  = [pageIndexes lastIndex];
		NSUInteger page;
		if (firstPage != NSNotFound)
		{
			id aNull = [NSNull null];
			for (page = firstPage; page <= lastPage; page++)
			{
				NSMutableArray* pageAssets = [self.assetPages objectAtIndex:page-1];
				if (pageAssets == aNull)
				{
					[self loadAssetPages:pageIndexes];
					pageAssets = [self.assetPages objectAtIndex:page-1];
				}
				
				for (DropIOAsset* thisAsset in pageAssets)
				{
					if ((thisAsset != nil) && [assetType isEqualToString:thisAsset.type])
						count++;
				}
			}
		}
	}
	return count;
}

/**
 * Returns an integer count of the {@link DropIOAsset}s of the given type in this drop.
 *
 * @param assetType
 * NSString containing the type of asset to be counted. Must be one of the kDropIOAssetType_* constants
 * defined in DropIOAsset.h.
 *
 * @return Integer count of the number of assets of the given type in this drop.
 */
- (NSUInteger) countAllAssetsOfType:(NSString*)assetType
{
	return [self countAssetsOfType:assetType inAssetPages:[self indexSetForAllAssetPages]];
}

#pragma mark -
#pragma mark Adding/Removing Assets
#pragma mark -

/**
 * Adds the given {@link DropIOAsset} object to this drop object's list of assets. This
 * method only manipulates objects in memory; it does NOT add the asset to the drop
 * on the drop.io website. To create an asset on the drop website, use one of the asset
 * creation methods listed below.
 *
 * @param asset
 * A {@link DropIOAsset} object to be added to this drop in memory.
 *
 * @see noteWithTitle:contents:
 * @see linkWithTitle:url:description:
 * @see docWithFilename:data:mimeType:
 * @see imageWithName:data:format:
 */
- (void) addAsset:(DropIOAsset*)asset
{
	[asset setDrop:self];
	[asset setValue:[[self URLForAssetNamed:[asset name]] absoluteString] forKey:kDropIOParamKey_AssetAPIUrl];
	
	NSUInteger lastPageIndex = [self lastAssetPageIndex];
	NSMutableArray* lastPageAssets = [self.assetPages objectAtIndex:lastPageIndex-1];
	if (lastPageAssets == (NSMutableArray*)[NSNull null])
	{
		[self loadAssetPages:[NSIndexSet indexSetWithIndex:lastPageIndex]];
		lastPageAssets = [self.assetPages objectAtIndex:lastPageIndex-1];
	}
		
	if ([lastPageAssets count] == kAssetsPerPage)
	{
		lastPageAssets = [[NSMutableArray alloc] initWithCapacity:kAssetsPerPage];
		[self.assetPages addObject:lastPageAssets];
		[lastPageAssets release];
	}
	
	[lastPageAssets addObject:asset];
	
	assetCount++;
	
//	[self sortAssets];
}

/**
 * Removes the given {@link DropIOAsset} object from this drop's list of assets and
 * permanently deletes the asset from the drop's website at drop.io.
 *
 * @param asset
 * A {@link DropIOAsset} object to be deleted from this drop.
 */
- (void) removeAsset:(DropIOAsset*)asset
{
	// No need to check canDelete method; let API return its error.
	[asset delete];
}

/**
 * Removes the {@link DropIOAsset} at the given index within the specified asset pages and
 * permanently deletes the asset from Drop.io.
 *
 * @param index
 * Integer index of the {@link DropIOAsset} object to be deleted from this drop.
 *
 * @param pageIndexes
 * NSIndexSet specifying the range of asset pages over which to count assets.
 */
- (void) removeAssetAtIndex:(NSUInteger)index inAssetPages:(NSIndexSet*)pageIndexes
{
	DropIOAsset* assetToRemove = (DropIOAsset*)[self assetAtIndex:index inAssetPages:pageIndexes];
	if (assetToRemove != nil)
		[self removeAsset:assetToRemove];
}

#pragma mark -
#pragma mark Creating Assets
#pragma mark -

/**
 * Basic bottleneck method for drop.io RESTful asset operations.
 *
 * @param opString
 * NSString containing the HTTP method to use in the Drop.io HTTP request.
 *
 * @param urlStr
 * NSString containing the Drop.io API URL for the asset operation.
 *
 * @param params
 * NSDictionary containing a set of name-value pairs to use in the body of the HTTP request.
 *
 * @return An autoreleased DropIOAsset object returned from the request, if present.
 */
- (DropIOAsset*) assetOperation:(NSString*)opString atUrl:(NSString*)urlStr withParameters:(NSDictionary*)params
{
	// clear any previous DropIOError
	[DropIO setLastError:nil];
	
	if (![DropIO checkAPIKey])
		return nil;
	
	// Create an HTTP URL request pointing to the drop.io API URL.
	NSMutableURLRequest* dropReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
	[dropReq setHTTPMethod:opString];	
	[dropReq setHTTPPostBody:params];	// Method added by NSMutableURLRequest(httpFormEncoding) category, defined above.
	
	// Send the request and get the drop XML response synchronously (for now).
	NSURLResponse* dropResp = nil;
	NSError* error = nil;
	NSData* dropXmlData = [NSURLConnection sendSynchronousRequest:dropReq 
												returningResponse:&dropResp 
															error:&error];
	
	[dropReq release];
	
	// dropResp should be autoreleased, but it leaks in iPhone OS prior to 2.2.
	// Some suggest using the call below to clean up the response object.
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	if (error != nil)
	{
		NSLog(@"HTTP %@ Error: %@", opString, error);
		[DropIO setLastError:error];
		return nil;
	}
	
	// Parse the XML into DropIOAsset object
	NSArray* propArray = [DropIO parseResponse:dropXmlData
								  fromNodeName:@"asset"
									  toObject:@"NSMutableDictionary"
									parseError:&error];
	if (propArray == nil || [propArray count] == 0)
		return nil;
	
	return [DropIOAsset assetWithProperties:[propArray objectAtIndex:0]];
}

/**
 * Creates a new Drop.io asset in the receiving drop from the given request parameters.
 *
 * @param params
 * NSDictionary containing name-value pairs specifying the properties of the new asset.
 * See <a href="http://groups.google.com/group/dropio-api/web/full-api-documentation">the Drop.io API documentation</a> for parameter datails.
 *
 * @return A new autoreleased {@link DropIOAsset} instance returned from the API.
 */
- (DropIOAsset*) assetWithParameters:(NSDictionary*)params
{
	DropIOAsset* asset = [self assetOperation:@"POST" 
										atUrl:[NSString stringWithFormat:kDropIONewAssetUrlFormat, [self name]]
							   withParameters:params];
	if (asset != nil)
	{
		[self addAsset:asset];
	}
	return asset;
}

/**
 * Creates a new note in this drop with the given title and contents.
 *
 * @param noteTitle
 * NSString containing the title to use for the note.
 *
 * @param text
 * NSString containing the text contents of the note.
 *
 * @return An autoreleased {@link DropIONote} object with the given title and contents 
 * which has been added to the drop.
 */
- (DropIONote*) noteWithTitle:(NSString*)noteTitle contents:(NSString*)text
{
	if (![DropIO checkAPIKey])
		return nil;
	
	NSString* token = [self bestTokenIncludingPassword:NO];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:6];
	[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:noteTitle							forKey:kDropIOParamKey_Title];
	[params setObject:text								forKey:kDropIOParamKey_Contents];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	
	return (DropIONote*)[self assetWithParameters:params];
}

/**
 * Creates a new link in this drop with the given title and description, pointing to the given URL.
 *
 * @param linkTitle
 * NSString containing the title for the link to use for display.
 *
 * @param linkURL
 * NSURL object pointing to the URL to be linked to.
 *
 * @param linkDesc
 * NSString containing the optional textual description for the link. May be nil.
 *
 * @return An autoreleased {@link DropIOLink} object with the given properties which
 * has been added to the drop.
 */
- (DropIOLink*) linkWithTitle:(NSString*)linkTitle url:(NSURL*)linkURL description:(NSString*)linkDesc
{
	if (![DropIO checkAPIKey])
		return nil;
	
	NSString* token = [self bestTokenIncludingPassword:NO];
	
	NSString* linkUrlStr = [linkURL absoluteString];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:7];
	[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:linkTitle							forKey:kDropIOParamKey_Title];
	[params setObject:linkUrlStr						forKey:kDropIOParamKey_Url];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	if (linkDesc != nil)
		[params setObject:linkDesc						forKey:kDropIOParamKey_Description];
	
	return (DropIOLink*)[self assetWithParameters:params];
}

/**
 * Creates a new document in this drop with the given filename, data, and MIME type.
 * Performs an HTTP file upload of the document to Drop.io.
 *
 * @param fileName
 * NSString containing the filename of the document.
 *
 * @param docData
 * NSData object containing the document data.
 *
 * @param docMimeType
 * NSString containing the format of the data, for example, "image/png", "application/msword", or "text/xml".
 *
 * @return An autoreleased {@link DropIODocument} object with the given properties which
 * has been added to the drop.
 */
- (DropIODocument*) docWithFilename:(NSString*)fileName
							   data:(NSData*)docData
						   mimeType:(NSString*)docMimeType
{
	// Must do an HTTP file upload to the URL http://assets.drop.io/upload
	
	if (![DropIO checkAPIKey])
		return nil;
	
	NSString* token = [self bestTokenIncludingPassword:NO];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:5];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	[params setObject:[self name]						forKey:kDropIOParamKey_DropName];
	
	// clear any previous DropIOError
	[DropIO setLastError:nil];
	
	NSLog(@"Uploading document named \"%@\" with params %@", fileName, params);
	
	// Create an HTTP POST URL request pointing to the drop.io API URL.
	NSString* boundary		= @"DropKitFileUpload";
	NSString* contentType	= [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	
	NSMutableURLRequest* uploadReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kDropIOFileUploadUrl]];
	[uploadReq setHTTPMethod:@"POST"];
	[uploadReq setValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *postBody = [NSMutableData dataWithCapacity:[docData length] + 512];
	
	// Add form parameters
	for (NSString* key in [params allKeys])
	{
		NSString* paramContent = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n",
								  boundary,
								  key,
								  [params objectForKey:key]
								  ];
		[postBody appendData:[paramContent dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	// Add file data parameter
	NSString* fileContentHeader = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type:%@\r\n\r\n",
								   boundary, 
								   [fileName stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
								   docMimeType];
	[postBody appendData:[fileContentHeader dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:docData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[uploadReq setHTTPBody:postBody];
	
	// Send the request and get the drop XML response synchronously (for now).
	NSURLResponse* uploadResp = nil;
	NSError* error = nil;
	NSData* xmlData = [NSURLConnection sendSynchronousRequest:uploadReq 
											returningResponse:&uploadResp 
														error:&error];
	
	[uploadReq release];
	
	// uploadResp should be autoreleased, but it leaks in iPhone OS prior to 2.2.
	// Some suggest using the call below to clean up the response object.
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	if (error != nil)
	{
		NSLog(@"HTTP File Upload Error: %@", error);
		[DropIO setLastError:error];
		return nil;
	}
	
	//NSString* xmlStr = [[NSString alloc] initWithData:xmlData encoding:NSASCIIStringEncoding];
	//NSLog(@"Drop.io API raw response data: %@", xmlStr);
	//[xmlStr release];
	
	// Parse the XML into DropIOAsset object
	NSArray* propArray = [DropIO parseResponse:xmlData
								  fromNodeName:@"asset"
									  toObject:@"NSMutableDictionary"
									parseError:&error];
	if (propArray == nil || [propArray count] == 0)
		return nil;
	
	DropIOAsset* asset = [DropIOAsset assetWithProperties:[propArray objectAtIndex:0]];
	if (asset != nil)
	{
		[self addAsset:asset];
	}
	return (DropIODocument*)asset;
}

/**
 * Creates a new image in this drop with the given name and image data in the given image format.
 * Performs an HTTP file upload of the image data to Drop.io.
 *
 * @param imgName
 * NSString containing the name of the image.
 *
 * @param imgData
 * NSData object containing the image data.
 *
 * @param imgDataFormat
 * NSString containing the format of the image data, for example, "png", "jpeg", or "gif".
 *
 * @return An autoreleased {@link DropIOImage} object with the given properties which
 * has been added to the drop.
 */
- (DropIOImage*) imageWithName:(NSString*)imgName data:(NSData*)imgData format:(NSString*)imgDataFormat 
{
	NSString* fileName = [NSString stringWithFormat:@"%@.%@", imgName, imgDataFormat];
	NSString* mimeType = [NSString stringWithFormat:@"image/%@", imgDataFormat];
	
	return  (DropIOImage*)[self docWithFilename:fileName data:imgData mimeType:mimeType];
}

#pragma mark -
#pragma mark Calling the Drop
#pragma mark -

/**
 * Passes the drop's voicemail URL to the application to open using any available "tel:" URL handler.
 * On the iPhone, this method will dial the drop's voicemail phone number.
 * On an iPod touch, this method does nothing.
 */
- (void) recordVoicemail
{
	// Pass voicemail URL to app's openURL method.
	[[NSApplication sharedApplication] openURL:[self voicemailURL]];
}

/**
 * Passes the drop's conference call URL to the application to open using any available "tel:" URL handler.
 * On the iPhone, this method will dial the drop's conference call phone number.
 * On an iPod touch, this method does nothing.
 */
- (void) conferenceCall
{
	// Pass conference URL to app's openURL method.
	[[NSApplication sharedApplication] openURL:[self conferenceURL]];
}

#pragma mark -
#pragma mark Drop Access Control
#pragma mark -

/**
 * Returns the best security token available for this drop, to be used in
 * Drop.io API requests. Returns the admin token if available, otherwise
 * it returns the guest token. If neither are available, and a user-supplied
 * password is available, and the <i>includePassword</i> parameter is true, then
 * the user-supplied password is returned as a last resort. If none of the above
 * are available, an empty string is returned.
 *
 * @param includePassword
 * Boolean flag indicating whether or not to return a user-supplied password as the token.
 *
 * @return NSString containing the best available security token.
 */
- (NSString*)bestTokenIncludingPassword:(BOOL)includePassword
{
	NSString* token = @"";
	if ((adminToken != nil) && (adminToken.length > 0))
		token = adminToken;
	else
	if ((guestToken != nil) && (guestToken.length > 0))
		token = guestToken;
	else
	if (includePassword && (password != nil) && (password.length > 0))
		token = password;
	
	return token;
}

// Determine access privileges for button enablement

/**
 * Returns true if the drop's current settings allow assets to be added to it.
 * Assets can be added if the drop has an admin token, or if the drop has
 * a guest token and the drop is configured to allow guests to add assets.
 *
 * @return Boolean true if assets can be added to the drop.
 */
- (BOOL) canAdd
{
	// User can add to drop if:
	// they have an admin token, or
	// they have a guest token AND guestsCanAdd is "true"
	
	// A nil token means no token was returned from the API,
	// which means no token is associated with the drop, which 
	// in turn means that no password or token is required for access.
	
	// An empty token, on the other hand, means that a token has
	// been associated with the drop, but the user has not supplied one
	// in the request. In that case, access is denied.
	
	return (((adminToken != nil) && (adminToken.length > 0))
		||  (((guestToken == nil) || (guestToken.length > 0)) && guestsCanAdd));
}

/**
 * Returns true if the drop's current settings allow assets to be edited/updated.
 * Assets can be updated if the drop has an admin token, or if the drop has
 * a guest token and the drop is configured to allow guests to add assets.
 *
 * @return Boolean true if the drop's assets can be updated.
 */
- (BOOL) canEdit
{
	// If you can add, you can edit.
	return [self canAdd];
}

/**
 * Returns true if the drop's current settings allow assets to be deleted.
 * Assets can be deleted if the drop has an admin token, or if the drop has
 * a guest token and the drop is configured to allow guests to delete assets.
 *
 * @return Boolean true if assets can be deleted from the drop.
 */
- (BOOL) canDelete
{
	// User can delete from drop if:
	// they have an admin token, or
	// they have a guest token AND guestsCanDelete is "true"
	
	// A nil token means no token was returned from the API,
	// which means no token is associated with the drop, which 
	// in turn means that no password or token is required for access.
	
	// An empty token, on the other hand, means that a token has
	// been associated with the drop, but the user has not supplied one
	// in the request. In that case, access is denied.
	
	return (((adminToken != nil) && (adminToken.length > 0))
		||  (((guestToken == nil) || (guestToken.length > 0)) && guestsCanDelete));
}

/**
 * Returns true if the drop's current settings allow comments to be added to it.
 * Comments can be added if the drop has an admin token, or if the drop has
 * a guest token and the drop is configured to allow guests to add comments.
 *
 * @return Boolean true if comments can be added to the drop.
 */
- (BOOL) canComment
{
	// User can add comments to drop assets if:
	// they have an admin token, or
	// they have a guest token AND guestsCanComment is "true"
	
	// A nil token means no token was returned from the API,
	// which means no token is associated with the drop, which 
	// in turn means that no password or token is required for access.
	
	// An empty token, on the other hand, means that a token has
	// been associated with the drop, but the user has not supplied one
	// in the request. In that case, access is denied.
	
	return (((adminToken != nil) && (adminToken.length > 0))
		||  (((guestToken == nil) || (guestToken.length > 0)) && guestsCanComment));
	
}

/**
 * Returns true if the drop has few enough assets to load all at once.
 * Currently, we only allow sorting of assets if the assetCount is lower
 * than a predefined threshold, because all the assets must be
 * held in memory in order to sort them. Hopefully, a future version
 * of the drop.io API will allow sorting assets through the API.
 *
 * @return Boolean true if all assets can be loaded into memory at once.
 */
- (BOOL) canLoadAllAssets
{
	return (assetCount <= kDropMaxAssets);
}

#pragma mark -
#pragma mark Updating/Deleting the Drop
#pragma mark -

/**
 * Updates Drop.io with this drop object's properties.
 */
- (void) update
{
	[DropIO setLastError:nil];

	// Must already have a valid token to update drop properties; don't include password
	NSString* token = [self bestTokenIncludingPassword:NO];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:11];
	
	// Required parameters
	[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	
	// Optional parameters
	if (guestPassword	 != nil)	[params setObject:guestPassword		forKey:kDropIOParamKey_GuestPassword];
	if (adminPassword	 != nil)	[params setObject:adminPassword		forKey:kDropIOParamKey_AdminPassword];
	if (premiumCode		 != nil)	[params setObject:premiumCode		forKey:kDropIOParamKey_PremiumCode];
	if (expirationLength != nil)	[params setObject:expirationLength	forKey:kDropIOParamKey_ExpirationLength];
	
	[params setObject:(guestsCanAdd     ? @"true" : @"false")	forKey:kDropIOParamKey_GuestsCanAdd];
	[params setObject:(guestsCanDelete  ? @"true" : @"false")	forKey:kDropIOParamKey_GuestsCanDelete];
	[params setObject:(guestsCanComment ? @"true" : @"false")	forKey:kDropIOParamKey_GuestsCanComment];
	
	[DropIO updateDropNamed:[self name] withParameters:params];
}

/**
 * Permanently deletes this drop and all of its assets from Drop.io.
 */
- (void) delete
{
	[DropIO setLastError:nil];
	
	// Must already have a valid token to delete drop properties; don't include password
	NSString* token = [self bestTokenIncludingPassword:NO];
	
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:4];
	
	// Required parameters
	[params setObject:kDropIOParamValue_Format_XML		forKey:kDropIOParamKey_Format];
	[params setObject:kDropIOParamValue_Version_Latest	forKey:kDropIOParamKey_Version];
	[params setObject:[DropIO APIKey]					forKey:kDropIOParamKey_APIKey];
	[params setObject:token								forKey:kDropIOParamKey_Token];
	
	[DropIO deleteDropNamed:[self name] withParameters:params];
	
	if ([DropIO lastError] != nil)
	{
		// For some reason the drop.io API returns a successful deletion in an error response.
		if ([[DropIO lastError] code] == kDropIOErrorCode_DropDeleted)
		{
			[DropIO setLastError:nil];
		}
	}
}

#pragma mark -
#pragma mark Key-Value Coding methods
#pragma mark -

/**
 * Sets the value for all keys not predefined for this object.
 * Used by Key-Value Coding (KVC) methods. In particular, this
 * method is called by the {@link XMLToObjectParser} class to set
 * values for drop properties not predefined by the DropIODrop class.
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
	// do nothing
//	NSLog(@"Undefined key: %@\n        value: %@\n  value class: %@\n    for class: %@", key, value, [value class], [self class]);
}

- (void)setValue:(id)value 
 forKey:(NSString *)key 
{
//	NSLog(@"Setting value: %@\n       forKey: %@\n  value class: %@\n    for class: %@", value, key, [value class], [self class]);
	
	if ([key isEqualToString:@"guestsCanAdd"]
	||  [key isEqualToString:@"guestsCanDelete"]
	||  [key isEqualToString:@"guestsCanComment"])
	{
		BOOL boolValue = [value isEqualToString:@"true"];
		//SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", [key uppercaseString]]);
		value = [NSNumber numberWithBool:boolValue];
		//[self performSelector:setter withObject:value];
	}
	else
	if ([key isEqualToString:@"maxBytes"]
	||  [key isEqualToString:@"currentBytes"]
	||  [key isEqualToString:@"assetCount"])
	{
		NSUInteger uintValue = [value integerValue];
		value = [NSNumber numberWithUnsignedInteger:uintValue];
	}
	[super setValue:value forKey:key];
}

#pragma mark -
#pragma mark Deprecated Methods
#pragma mark -

/**
 * Loads all assets in the drop.
 *
 * @deprecated
 * @see #loadAllAssets
 */
- (void) loadAssets
{
	// replaced by loadAllAssets
	[self loadAllAssets];
}

/**
 * Unloads all assets in the drop.
 *
 * @deprecated
 * @see #unloadAllAssets
 */
- (void) unloadAssets
{
	// replaced by unloadAllAssets
	[self unloadAllAssets];
}

/**
 * Reloads all assets in the drop.
 *
 * @deprecated
 * @see #reloadAllAssets
 */
- (void) reloadAssets
{
	// replaced by reloadAllAssets
	[self reloadAllAssets];
}

/**
 * Returns true if all of the drop's {@link DropIOAsset} objects have been loaded.
 *
 * @return Boolean true if all assets have been loaded.
 * @deprecated
 * @see #areAllAssetsLoaded
 */
- (BOOL) areAssetsLoaded
{
	// replaced by areAllAssetsLoaded
	return [self areAllAssetsLoaded];
}

/**
 * Sorts the drop's {@link #assets} array according to the drop's {@link #sortOrder} setting.
 *
 * @deprecated
 * @see #sortAllAssets
 */
- (void) sortAssets
{
	// replaced by sortAllAssets
	[self sortAllAssets];
}

/**
 * Returns an integer count of the {@link DropIOAsset}s of the given type in this drop.
 *
 * @param assetType
 * NSString containing the type of asset to be counted. Must be one of the kDropIOAssetType_* constants
 * defined in DropIOAsset.h.
 *
 * @return Integer count of the number of assets of the given type in this drop.
 *
 * @deprecated
 * @see #countAllAssetsOfType:
 */
- (NSInteger) countAssetsOfType:(NSString*)assetType
{
	// replaced by countAllAssetsOfType:
	return [self countAllAssetsOfType:assetType];
}

/**
 * Finds a {@link DropIOAsset} object in this drop with the given name.
 * If not found in the {@link #assetPages} array, the object is loaded from Drop.io
 * if <i>loadFlag</i> is set.
 *
 * @param assetName
 * NSString containing the name of the asset to find in this drop.
 *
 * @param loadFlag
 * Boolean flag indicating that the {@link DropIOAsset} object should be loaded 
 * from Drop.io if it is not already loaded.
 *
 * @return An autoreleased {@link DropIOAsset} object with the given name.
 *
 * @deprecated
 * @see #findAssetNamed:loadAllIfMissing:
 */
- (DropIOAsset*) findAssetNamed:(NSString*)assetName loadIfMissing:(BOOL)loadFlag
{
	return [self findAssetNamed:assetName loadAllIfMissing:loadFlag];
}

/**
 * Returns the {@link DropIOAsset} object at the given index in the drop's list of assets.
 *
 * @param index
 * Integer index of the desired asset in this drop.
 *
 * @return The autoreleased {@link DropIOAsset} object at the given index.
 *
 * @deprecated
 * @see #assetAtIndex:inAssetPages:
 */
- (DropIOAsset*) assetAtIndex:(NSInteger)index
{
	return [self assetAtIndex:index inAssetPages:[self indexSetForAllAssetPages]];
}

- (void) removeAssetAtIndex:(NSInteger)index
{
	[self removeAssetAtIndex:index inAssetPages:[self indexSetForAllAssetPages]];
}

@end
