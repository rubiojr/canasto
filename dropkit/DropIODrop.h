//
//  DropIODrop.h
//  DropIO
//
//  Created by Chris Patterson on 11/10/08.
//  Copyright 2008 Chris Patterson. All rights reserved.
//

#include <AppKit/AppKit.h>

@class DropIOAsset;
@class DropIONote;
@class DropIOLink;
@class DropIODocument;
@class DropIOImage;

typedef enum {
	AssetSortOrder_Date = 0,	// Sort assets by date descending (like "blog" view)
	AssetSortOrder_Type = 1,	// Sort assets by type name ascending (like "media" view)
	AssetSortOrder_Title = 2,	// Sort assets by asset name ascending
	AssetSortOrder_API = 3		// Don't sort assets -- list them in the order they come from the API.
} AssetSortOrder;

typedef enum {
	kDropFeedFormat_RSS = 0,
	kDropFeedFormat_Dropcast
} DropFeedFormat;

@interface DropIODrop : NSObject {

	NSString*		name;					///< Name of the drop; used in drop URL
	NSString*		password;				///< Password entered by user to access drop; only used for first access
	
	NSString*		adminPassword;			///< Admin password; only used when creating a new drop.
	NSString*		guestPassword;			///< Guest password; only used when creating a new drop.
	NSString*		adminToken;				///< String token or password used to gain admin access
	NSString*		guestToken;				///< String token or password used to gain guest access
	
	NSString*		email;					///< Email address to which you can send to add to drop
	NSString*		voicemail;				///< Telephone number to which you can record audio to add to drop
	NSString*		conference;				///< Telephone number to use for phone conferencing
	
	NSString*		rss;					///< RSS feed URL for drop contents
	NSString*		fax;					///< Fax cover sheet URL for faxing documents to drop
	NSString*		hiddenUploadUrl;		///< Url of a web page that uploads to this drop without revealing the drop's identity 
	
	NSString*		expirationLength;		///< String token indicating drop expiration
	NSUInteger		currentBytes;			///< Current total size of assets stored in this drop
	NSUInteger		maxBytes;				///< Maximum total size of assets that can be stored in this drop

	NSUInteger		assetCount;				///< Count of assets (files) stored in drop

	BOOL			guestsCanAdd;			///< True if guests can add to drop
	BOOL			guestsCanDelete;		///< True if guests can delete from drop
	BOOL			guestsCanComment;		///< True if guests can add comments to drop
	
	NSString*		premiumCode;			///< Access code to enable premium drop features; only used when creating a new drop.
	
	NSMutableArray*	assetPages;				///< Array of arrays of DropIOAsset objects; one array per asset page
	
	NSString*		title;					///< Human-readable title for drop; taken from Drops.plist
	AssetSortOrder	sortOrder;				///< Sort order of assets array; default by type then title
	NSMutableArray*	sortedAssets;			///< Sorted array of assets resulting from last call to {@link sortAssetPages:}
	NSIndexSet*		sortedPageIndexes;		///< Page indexes of asset pages sorted by last call to {@link sortAssetPages:}
	
	BOOL			loadingAssets;			///< Flag indicating that {@link #loadAssets} thread is running in background.
}

@property (nonatomic, retain) NSString*			name;
@property (nonatomic, retain) NSString*			password;

@property (nonatomic, retain) NSString*			adminPassword;
@property (nonatomic, retain) NSString*			guestPassword;
@property (nonatomic, retain) NSString*			adminToken;
@property (nonatomic, retain) NSString*			guestToken;

@property (nonatomic, retain) NSString*			email;
@property (nonatomic, retain) NSString*			voicemail;
@property (nonatomic, retain) NSString*			conference;

@property (nonatomic, retain) NSString*			rss;
@property (nonatomic, retain) NSString*			fax;
@property (nonatomic, retain) NSString*			hiddenUploadUrl;

@property (nonatomic, retain) NSString*			expirationLength;
@property (nonatomic)         NSUInteger		currentBytes;
@property (nonatomic)         NSUInteger		maxBytes;

@property (nonatomic)         NSUInteger		assetCount;

@property (nonatomic)         BOOL				guestsCanAdd;
@property (nonatomic)         BOOL				guestsCanDelete;
@property (nonatomic)         BOOL				guestsCanComment;

@property (nonatomic, retain) NSString*			premiumCode;

@property (retain)			  NSMutableArray*	assetPages;

@property (nonatomic, retain) NSString*			title;
@property (nonatomic)		  AssetSortOrder	sortOrder;
@property (nonatomic, retain) NSMutableArray*	sortedAssets;
@property (nonatomic, retain) NSIndexSet*		sortedPageIndexes;

@property					  BOOL				loadingAssets;

// Accessors returning above properties as NSURLs
- (NSURL*) emailURL;		// returns a "mailto:" URL.
- (NSURL*) voicemailURL;	// returns a "tel:" URL.
- (NSURL*) conferenceURL;	// returns a "tel:" URL.
- (NSURL*) rssURL;
- (NSURL*) faxURL;
- (NSURL*) hiddenUploadURL;

- (NSURL*) dropURL;
- (NSURL*) apiURL;
- (NSURL*) dropcastURL;		// returns an "itpc:" URL from the rss URL.
- (NSURL*) feedURLForFormat:(DropFeedFormat)format;
- (NSURL*) mobileURL;
- (NSURL*) chatURL;
- (NSURL*) webAuthURL;

// Asset URLs
- (NSURL*) URLForAssetsPage:(NSUInteger)assetsPage;
- (NSURL*) URLForAssetNamed:(NSString*)assetName;

// Getting NSIndexSets and asset page indexes
- (NSIndexSet*) indexSetForAllAssetPages;
- (NSUInteger) lastAssetPageIndex;

// Loading Assets
- (void) loadAssetPages:(NSIndexSet*)pageIndexes;
- (void) loadAssetPagesInBackground:(NSIndexSet*)pageIndexes;
- (void) loadAllAssets;
- (void) loadAllAssetsInBackground;

// Unloading Assets
- (void) unloadAssetPages:(NSIndexSet*)pageIndexes;
- (void) unloadAllAssets;

// Reloading Assets
- (void) reloadAssetPages:(NSIndexSet*)pageIndexes;
- (void) reloadAssetPagesInBackground:(NSIndexSet*)pageIndexes;
- (void) reloadAllAssets;
- (void) reloadAllAssetsInBackground;

// Checking for Loaded Assets
- (BOOL) areAssetPagesLoaded:(NSIndexSet*)pageIndexes;
- (BOOL) areAllAssetsLoaded;

// Sorting Assets
- (void) sortAssetPages:(NSIndexSet*)pageIndexes;
- (void) sortAllAssets;

// Counting Assets
- (NSUInteger) countAssetsInAssetPages:(NSIndexSet*)pageIndexes;
- (NSUInteger) countAllAssets;
- (NSUInteger) countAssetsOfType:(NSString*)assetType inAssetPages:(NSIndexSet*)pageIndexes;
- (NSUInteger) countAllAssetsOfType:(NSString*)assetType;

// Finding Assets
- (DropIOAsset*) findAssetNamed:(NSString*)assetName inAssetPages:(NSIndexSet*)pageIndexes loadIfMissing:(BOOL)loadFlag;
- (DropIOAsset*) findAssetNamed:(NSString*)assetName loadAllIfMissing:(BOOL)loadFlag;
- (DropIOAsset*) assetAtIndex:(NSUInteger)index inAssetPages:(NSIndexSet*)pageIndexes;

// Adding/Removing Assets
- (void) addAsset:(DropIOAsset*)asset;
- (void) removeAsset:(DropIOAsset*)asset;
- (void) removeAssetAtIndex:(NSUInteger)index inAssetPages:(NSIndexSet*)pageIndexes;

// Creating Assets
- (DropIOAsset*)	assetOperation:(NSString*)opString atUrl:(NSString*)urlStr withParameters:(NSDictionary*)params;
- (DropIOAsset*)	assetWithParameters:(NSDictionary*)propDict;
- (DropIONote*)		noteWithTitle:(NSString*)noteTitle contents:(NSString*)text;
- (DropIOLink*)		linkWithTitle:(NSString*)linkTitle url:(NSURL*)linkURL description:(NSString*)linkDesc;
- (DropIODocument*) docWithFilename:(NSString*)fileName data:(NSData*)docData mimeType:(NSString*)docMimeType;
- (DropIOImage*)	imageWithName:(NSString*)imgName data:(NSData*)imgData format:(NSString*)imgDataFormat;

// Calling the Drop
- (void) recordVoicemail;
- (void) conferenceCall;

// Return best available token; ie. admin then guest then (optionally) password. Returns a blank string if all are nil.
- (NSString*)bestTokenIncludingPassword:(BOOL)includePassword;

// Determine access privileges for button enablement
- (BOOL) canAdd;
- (BOOL) canEdit;
- (BOOL) canDelete;
- (BOOL) canComment;
- (BOOL) canLoadAllAssets;

// Update and Delete
- (void) update;
- (void) delete;

// Deprecated methods for drops whose assetCount < kDropMaxAssets
- (void) loadAssets;									// replaced by loadAllAssets
- (void) unloadAssets;									// replaced by unloadAllAssets
- (void) reloadAssets;									// replaced by reloadAllAssets
- (BOOL) areAssetsLoaded;								// replaced by areAllAssetsLoaded
- (void) sortAssets;									// replaced by sortAllAssets
- (NSInteger) countAssetsOfType:(NSString*)assetType;	// replaced by countAllAssetsOfType:
- (DropIOAsset*) findAssetNamed:(NSString*)assetName loadIfMissing:(BOOL)loadFlag;
- (DropIOAsset*) assetAtIndex:(NSInteger)index;
- (void) removeAssetAtIndex:(NSInteger)index;


@end
