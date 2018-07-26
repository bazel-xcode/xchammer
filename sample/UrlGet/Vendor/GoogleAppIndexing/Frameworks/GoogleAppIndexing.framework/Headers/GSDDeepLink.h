//
//  GSDDeepLink.h
//  Google Search Platform iOS SDK
//
//  Copyright 2015 Google Inc.
//

// This class is meant to handle deep links URLs sent from Google Search result pages
// and will return the sanitized URL (with GSD specific query params removed).
//
// Deeplinks are expected in the following format:
//
// Format:
// gsd-<scheme>://<appstore-id>/?google-deep-link=<url-encoded-original-deeplink>&
//    google-callback-url=<url-encoded-callback-url>&google-min-sdk-version=<minimum-sdk-version>
//
// Example:
// Original Annotation: ios-app://544007664/vnd.youtube/www.youtube.com/watch?v=aISUYHTkTOU
// Original Deeplink: vnd.youtube://www.youtube.com/watch?v=aISUYHTkTOU
// Callback URL: googleapp://
// Final URL: gsd-vnd.youtube://544007664/?
//    google-deep-link=vnd.youtube%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DaISUYHTkTOU&
//    google-callback-url=googleapp%3A%2F%2F&
//    google-min-sdk-version=1.0.0
//
// These deep link URLs are validated by checking the scheme of the deeplink, which must have a
// 'gsd-' prefix. These URLs must also have the Google Callback & Google Min SDK URL query parameter
// (i.e 'google-callback-url', 'google-deep-link' & 'google-min-sdk-version') present.
// Deep link URLs which do not have the above properties will be ignored and will be returned as is.
//
// If the deep link URL is validated, a bar will be displayed at the top of the screen overlaying
// the status bar which will allow the user to return to their Google Search results. This bar will
// disappear after a short delay.
//
//

@interface GSDDeepLink : NSObject

/**
 * @method handleDeepLink:
 * @abstract Handles a deep link and displays a back bar if the URL is valid.
 * @param deeplinkURL The deeplink URL.
 * @return The sanitized URL (with GSD specific query params removed).
 */
+ (NSURL *)handleDeepLink:(NSURL *)deeplinkURL;

/**
 * @method isDeepLinkFromGoogleSearch:
 * @abstract Whether the deeplink URL has come from Google Search.
 * @param deeplinkURL The deeplink URL. This should NOT be the sanitized URL returned from
 *     handleDeepLink:
 * @return A BOOL indicating whether the deeplink URL is coming from Google Search.
 */
+ (BOOL)isDeepLinkFromGoogleSearch:(NSURL *)deepLinkURL;

/**
 * @method isDeepLinkFromGoogleAppCrawler:
 * @abstract Whether the deeplink URL has come from Google App Crawler.
 * @param deeplinkURL The deeplink URL. This should NOT be the sanitized URL returned from
 *     handleDeepLink:
 * @return A BOOL indicating whether the deeplink URL is coming from Google App Crawler.
 */
+ (BOOL)isDeepLinkFromGoogleAppCrawler:(NSURL *)deepLinkURL;

@end
