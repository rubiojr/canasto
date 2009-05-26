//
//  DropIO.h
//  DropIO
//
//  Created by Chris Patterson on 11/11/08.
//  Copyright 2008 Chris Patterson. All rights reserved.
//

#import "DropIODrop.h"
#import "DropIOAsset.h"

/**
 * DropIOErrorDomain constants for creating custom NSErrors
 */

/** Error Domain constant */
#define kDropIOErrorDomain	@"DropIOErrorDomain"

/** NSError.userInfo key constants */
#define kDropIOErrorAction	@"action"
#define kDropIOErrorMessage	@"message"
#define kDropIOErrorResult	@"result"
#define kDropIOErrorAPIURL	@"APIURL"

/** NSError.code value constants */
#define kDropIOErrorCode_RateLimitExceeded		-1
#define kDropIOErrorCode_NotDropURL				-2
#define kDropIOErrorCode_TokenInvalid			-3
#define kDropIOErrorCode_AssetCreationFailed	-4
#define kDropIOErrorCode_AssetDeleted			-5
#define kDropIOErrorCode_DropDeleted			-6
#define kDropIOErrorCode_SendToSuccess			-7
#define kDropIOErrorCode_Unknown				-1000

/** NSError.userInfo result string constants */
#define kDropIOErrorResult_Success				@"Success"

/** NSError.userInfo message string constants */
#define kDropIOErrorMessage_TokenInvalid		@"The token is invalid."
#define kDropIOErrorMessage_RateLimitExceeded	@"IP limit exceeded."
#define kDropIOErrorMessage_AssetCreationFailed	@"The asset could not be created."
#define kDropIOErrorMessage_AssetDeleted		@"The asset was destroyed."
#define kDropIOErrorMessage_DropDeleted			@"The drop was destroyed."

/** Drop.io API parameter key constants */
#define kDropIOParamKey_Version					@"version"
#define kDropIOParamKey_Format					@"format"
#define kDropIOParamKey_APIKey					@"api_key"
#define kDropIOParamKey_Name					@"name"
#define kDropIOParamKey_AdminPassword			@"admin_password"
#define kDropIOParamKey_GuestPassword			@"password"
#define kDropIOParamKey_Token					@"token"
#define kDropIOParamKey_Page					@"page"
#define kDropIOParamKey_Title					@"title"
#define kDropIOParamKey_Contents				@"contents"
#define kDropIOParamKey_Url						@"url"
#define kDropIOParamKey_Description				@"description"
#define kDropIOParamKey_DropName				@"drop_name"
#define kDropIOParamKey_PremiumCode				@"premium_code"
#define kDropIOParamKey_ExpirationLength		@"expiration_length"
#define kDropIOParamKey_GuestsCanAdd			@"guests_can_add"
#define kDropIOParamKey_GuestsCanDelete			@"guests_can_delete"
#define kDropIOParamKey_GuestsCanComment		@"guests_can_comment"
#define kDropIOParamKey_Type					@"type"
#define kDropIOParamKey_Medium					@"medium"
#define kDropIOParamKey_Emails					@"emails"
#define kDropIOParamKey_Message					@"message"
#define kDropIOParamKey_FaxNumber				@"fax_number"

#define kDropIOParamKey_AssetAPIUrl				@"assetAPIUrl"

/** Drop.io API parameter value constants */
#define kDropIOParamValue_Format_XML			@"xml"
#define kDropIOParamValue_Format_JSON			@"json"

#define kDropIOParamValue_Version_10			@"1.0"
#define kDropIOParamValue_Version_Latest		kDropIOParamValue_Version_10

#define kDropIOParamValue_Medium_Email			@"email"
#define kDropIOParamValue_Medium_Drop			@"drop"
#define kDropIOParamValue_Medium_Fax			@"fax"


/** Drop.io URL constants */
#define kDropIONewDropUrl						@"http://api.drop.io/drops"
#define kDropIOUpdateDropUrlFormat				@"http://api.drop.io/drops/%@"
#define kDropIODropUrlFormat					@"http://api.drop.io/drops/%@?%@=%@&%@=%@&%@=%@&%@=%@"
#define kDropIOAssetsUrlFormat					@"http://api.drop.io/drops/%@/assets?%@=%@&%@=%@&%@=%@&%@=%@&%@=%d"
#define kDropIONewAssetUrlFormat				@"http://api.drop.io/drops/%@/assets"
#define kDropIOUpdateAssetUrlFormat				@"http://api.drop.io/drops/%@/assets/%@"
#define kDropIOAssetUrlFormat					@"http://api.drop.io/drops/%@/assets/%@?%@=%@&%@=%@&%@=%@&%@=%@"
#define kDropIOSendAssetUrlFormat				@"http://api.drop.io/drops/%@/assets/%@/send_to"
#define kDropIOFileUploadUrl					@"http://assets.drop.io/upload"
#define kDropIODropWebUrlFormat					@"http://drop.io/%@"
#define kDropIODropMobileUrlFormat				@"http://drop.io/%@/m"
#define kDropIODropChatUrlFormat				@"http://drop.io/%@/chat?mobile=true"
#define kDropIODropWebAuthUrlFormat				@"http://drop.io/%@/from_api"

/** Number of assets returned at a time from the drop.io API assets request. */
#define kAssetsPerPage							 30

/** 
 * Maximum number of drop assets we can hold in memory at once. Should be a multiple of kAssetsPerPage. 
 * @see DropIODrop#canLoadAllAssets
 */
#define kDropMaxAssets							(10*kAssetsPerPage)

/**
 * NSString category to encode a string so it can be used in an HTTP POST body.
 * Used by NSMutableURLRequest(httpFormEncoding) category, below.
 */
@interface NSString (httpFormEncoding)
- (NSString*)stringUsingHTTPFormEncoding;
@end

/**
 * NSMutableURLRequest category to provide a method to
 * set the HTTP POST body from a dictionary of parameters.
 * Used in DropIODrop factory methods, below.
 */
@interface NSMutableURLRequest (httpFormEncoding)
- (void) setHTTPPostBody:(NSDictionary*)postParams;
@end

/**
 * DropIO class which provides static DropIODrop factory methods.
 */
@interface DropIO : NSObject

// Set API key
+ (void) setAPIKey:(NSString*)apiKey;

// Get API key
+ (NSString*)APIKey;

// Check that API key has been set
+ (BOOL) checkAPIKey;

// Parse API response data
+ (NSArray*) parseResponseFromURL:(NSURL*)url
					 fromNodeName:(NSString *)nodeName
						 toObject:(NSString *)className 
					   parseError:(NSError **)error;

+ (NSArray*) parseResponse:(NSData*)responseData
			  fromNodeName:(NSString *)nodeName
				  toObject:(NSString *)className 
				parseError:(NSError **)error;

// Basic bottleneck method for Drop.io RESTful drop operations
+ (DropIODrop*) dropOperation:(NSString*)opString atUrl:(NSString*)urlStr withParameters:(NSDictionary*)params;

// Creates a new drop with a random name
+ (DropIODrop*) dropWithRandomName;

// Creates a new drop with the given name
+ (DropIODrop*) dropWithName:(NSString*)aName;

// Creates a new drop with the given name and security password
+ (DropIODrop*) dropWithName:(NSString*)aName andPassword:(NSString*)aPassword;

// Create a new drop with the given parameters
+ (DropIODrop*) dropWithParameters:(NSDictionary*)params;

// Return API URL for drop with given name and security token/password
+ (NSURL*) URLForDropNamed:(NSString*)dropName withToken:(NSString*)aToken;

// Find an existing drop with the given name
+ (DropIODrop*) findDropNamed:(NSString*)aName error:(NSError**)pError;

// Find an existing drop with the given name and security token/password
+ (DropIODrop*) findDropNamed:(NSString*)aName withToken:(NSString*)aToken error:(NSError**)pError;

// Find drop from an api.drop.io API drop URL
+ (DropIODrop*) findDropAtAPIURL:(NSURL*)dropAPIURL error:(NSError**)pError;

// Return drop name from a drop.io drop URL
+ (NSString*) dropNameFromDropURL:(NSURL*)dropURL;

// Find drop from a drop.io drop URL
+ (DropIODrop*) findDropAtDropURL:(NSURL*)dropURL error:(NSError**)pError;

// Update an existing drop with the given parameters
+ (void) updateDropNamed:(NSString*)dropName withParameters:(NSDictionary*)params;

// Delete an existing drop with the given parameters
+ (void) deleteDropNamed:(NSString*)dropName withParameters:(NSDictionary*)params;

// Get last error received from drop.io API
+ (NSError*) lastError;
+ (void) setLastError:(NSError*)dropioError;

@end
