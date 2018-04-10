//
//  NSCharacterSet+Stripe.h
//  Stripe
//
//  Created by Brian Dorfman on 6/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCharacterSet (Stripe)

+ (instancetype)stp_asciiDigitCharacterSet;
+ (instancetype)stp_invertedAsciiDigitCharacterSet;


@end

void linkNSCharacterSetCategory(void);
