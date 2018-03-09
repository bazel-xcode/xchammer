//
//  GSDAppIndexing
//  Google Search Platform iOS SDK
//
//  Copyright 2015 Google Inc.
//

// This class is meant to register apps with Google for the purposes for App Indexing from
// Google Search.

@interface GSDAppIndexing : NSObject

/**
 * @method sharedInstance
 * @abstract returns the singleton instance of GSDAppIndexing
 * @return The shared instance of GSDAppIndexing
 */
+ (instancetype)sharedInstance;

/**
 * @method registerApp
 * @abstract Registers an app with Google for App Indexing purposes.
 * @param iTunesID The iTunes ID of the app.
 */
- (void)registerApp:(NSUInteger)iTunesID;

@end
