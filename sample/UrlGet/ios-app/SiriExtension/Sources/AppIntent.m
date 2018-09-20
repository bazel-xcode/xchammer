//
//  IntentHandler.m
//  SiriExtension
//
//  Created by XC Hammer
//

#import "PIIntentHandler.h"

@interface PIIntentHandler ()

#ifdef __IPHONE_10_0
    <INSearchForPhotosIntentHandling>
#endif

@end

@implementation PIIntentHandler

#ifdef __IPHONE_10_0

- (id)handlerForIntent:(INIntent *)intent
{
    id handler = nil;

    if ([intent isKindOfClass:[INSearchForPhotosIntent class]]) {
        handler = self;
    }

    return handler;
}

#pragma mark - INSearchForPhotosIntentHandling

- (void)handleSearchForPhotos:(INSearchForPhotosIntent *)searchForPhotosIntent completion:(void (^)(INSearchForPhotosIntentResponse *searchForPhotosIntentResponse))completion
{
    // completion(response);
}

#endif

@end
