//
//  DropIOAsset.h
//  DropIO
//
//  Created by Chris Patterson on 11/12/08.
//  Copyright 2008 Chris Patterson. All rights reserved.
//

@class DropIODrop;

// DropIOAsset.type constants

#define kDropIOAssetType_Note		@"note"
#define kDropIOAssetType_Link		@"link"
#define kDropIOAssetType_Document	@"document"
#define kDropIOAssetType_Image		@"image"
#define kDropIOAssetType_Audio		@"audio"
#define kDropIOAssetType_Movie		@"movie"
#define kDropIOAssetType_Other		@"other"

@interface DropIOAsset : NSObject {

	/**
	 * All asset properties are stored in a dictionary.
	 * Property keys and their meaning:
	 *
	 * <dl>
	 *	 <dt>"name"
	 *	 <dd>String containing name of asset used to identify it in URLs and API.
	 *
	 *	 <dt>"type"
	 *	 <dd>String containing type of asset; one of: note, link, document, image, movie, audio.
	 *
	 *	 <dt>"title"
	 *	 <dd>String containing human-readable descriptive title for asset.
	 *
	 *	 <dt>"description"
	 *	 <dd>String containing human-readable long-format description of asset.
	 *
	 *	 <dt>"filesize"
	 *	 <dd>Number containing size of the asset, in bytes.
	 *
	 *	 <dt>"createdAt"
	 *	 <dd>Date containing creation date/time.
	 *
	 *	 <dt>"status"
	 *	 <dd>String containing conversion status of asset; one of: "converted", "unconverted".
	 *	 For image, audio, and document types, the "converted" URL is not available until status is "converted".
	 *
	 *	 <dt>"hiddenUrl"
	 *	 <dd>String containing url to original asset without revealing drop's base URL or name.
	 *
	 *	 <dt>"thumbnail"
	 *	 <dd>Only for type: image, movie.
	 *	 String containing url of preview image up to 100x100px.
	 *
	 *	 <dt>"file"
	 *	 <dd>Only for type: image, audio, movie, document or status: unconverted.
	 *	 String containing url of original file; special access api key required.
	 *	 
	 *	 <dt>"converted"
	 *	 <dd>Only for type: image, audio, document.
	 *	 String containing url of converted file.
	 *	 
	 *	 <dt>"pages"
	 *	 <dd>Only for type: document. Number of pages in document.
	 *
	 *	 <dt>"duration"
	 *	 <dd>Only for type: movie, audio.
	 *	 <dd>duration of content, in seconds.
	 *	 
	 *	 <dt>"artist"
	 *	 <dt>"trackTitle"
	 *	 <dd>Only for type: audio.
	 *	 <dd>Strings containing ID3 tags of content.
	 *	 
	 *	 <dt>"height"
	 *	 <dt>"width"
	 *	 <dd>Only for type: image.
	 *	 <dd>Pixel height and width of original content.
	 *	 
	 *	 <dt>"contents"
	 *	 <dd>Only for type: note.
	 *	 <dd>String containing HTML-encoded text of content.
	 *	 
	 *	 <dt>"url"
	 *	 <dd>Only for type: link.
	 *	 <dd>String containing link url.
	 * </dl>
	 */
	NSMutableDictionary*	properties;
	
	DropIODrop*				drop;	///< {@link DropIODrop} object that owns this asset
}

// Synthesized property methods are implemented to read/write from properties dictionary.

@property (nonatomic, retain) NSMutableDictionary*	properties;
@property (nonatomic, retain) NSString*				name;
@property (nonatomic, retain) NSString*				type;
@property (nonatomic, retain) NSString*				title;
@property (nonatomic, retain) NSString*				description;
@property (nonatomic, retain) NSNumber*				filesize;
@property (nonatomic, retain) NSDate*				createdAt;
@property (nonatomic, retain) NSString*				status;
@property (nonatomic, retain) NSURL*				hiddenUrl;
@property (nonatomic, readonly) NSImage*			icon;
@property (nonatomic, retain) DropIODrop*			drop;

// Static factory methods

+ (DropIOAsset*) assetWithProperties:(NSMutableDictionary*)propDict;

// Instance methods

- (id)		init;
- (void)	dealloc;
- (void)	update;
- (void)	delete;
- (void)	releaseThumbnail;
- (BOOL)	isEditable;

// Send methods

- (void) sendWithParameters:(NSDictionary*)params;
- (void) sendToEmail:(NSArray*)emailAddressArray message:(NSString*)optionalMessageText;
- (void) sendToDropNamed:(NSString*)dropName;
- (void) sendToFax:(NSString*)faxNumber;

// Any unrecognized properties are stored in the properties dictionary

- (void)	setValue:(id)value forUndefinedKey:(NSString *)key;

@end

// Asset subclasses: Note, Link, Image, Document, Audio, Movie
// Their accessor methods also read/write from inherited properties dictionary

@interface DropIONote : DropIOAsset {
}
@property (nonatomic, retain) NSString* contents;
- (BOOL) isEditable;
@end

@interface DropIOLink : DropIOAsset {
}
@property (nonatomic, retain) NSURL* url;
- (BOOL) isEditable;
@end

@interface DropIOImage : DropIOAsset {
	NSImage*		thumbImage;		///< cached thumbnail image
	id				loadedTarget;	///< NSObject to notify when thumbnail is loaded
	SEL				loadedSel;		///< method selector to call when thumbnail is loaded
}
@property (nonatomic, retain) NSURL*	thumbnail;
@property (nonatomic, retain) NSURL*	file;
@property (nonatomic, retain) NSURL*	converted;
@property (nonatomic, retain) NSNumber*	height;
@property (nonatomic, retain) NSNumber*	width;
@property (nonatomic, retain) NSImage*	thumbImage;
- (id)   init;
- (BOOL) isThumbnailLoaded;
- (void) whenThumbnailIsLoadedPerformSelector:(SEL)selector target:(id)obj;
- (void) releaseThumbnail;
@end

@interface DropIODocument : DropIOAsset {
}
@property (nonatomic, retain) NSURL*	file;
@property (nonatomic, retain) NSURL*	converted;
@property (nonatomic, retain) NSNumber*	pages;
@end

@interface DropIOAudio : DropIOAsset {
}
@property (nonatomic, retain) NSURL*	file;
@property (nonatomic, retain) NSURL*	converted;
@property (nonatomic, retain) NSNumber*	duration;
@property (nonatomic, retain) NSString*	artist;
@property (nonatomic, retain) NSString*	trackTitle;
@end

@interface DropIOMovie : DropIOAsset {
	NSImage*		thumbImage;		///< cached thumbnail image
	id				loadedTarget;	///< NSObject to notify when thumbnail is loaded
	SEL				loadedSel;		///< method selector to call when thumbnail is loaded
}
@property (nonatomic, retain) NSURL*	thumbnail;
@property (nonatomic, retain) NSURL*	converted;
@property (nonatomic, retain) NSURL*	file;
@property (nonatomic, retain) NSNumber*	duration;
@property (nonatomic, retain) NSImage*	thumbImage;
- (BOOL) isThumbnailLoaded;
- (void) whenThumbnailIsLoadedPerformSelector:(SEL)selector target:(id)obj;
- (void) releaseThumbnail;
@end
/*
@interface DropIOArchive : DropIOAsset {
}
@property (nonatomic, retain) NSURL*	file;
@property (nonatomic, retain) NSURL*	converted;
@end
*/
