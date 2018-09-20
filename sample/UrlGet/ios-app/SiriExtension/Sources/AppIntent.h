//
//  IntentHandler.h
//  SiriExtension
//
//  Created by XC Hammer
//

@import Foundation;
#ifdef __IPHONE_10_0

#import <Intents/Intents.h>

@interface XCIntentHandler : INExtension

#else

@interface XCIntentHandler : NSObject

#endif

@end
