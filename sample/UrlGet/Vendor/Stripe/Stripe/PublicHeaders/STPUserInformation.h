//
//  STPUserInformation.h
//  Stripe
//
//  Created by Jack Flintermann on 6/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAddress.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  You can use this class to specify information that you've already collected from your user. You can then set the `prefilledInformation` property on `STPPaymentContext`, `STPAddCardViewController`, etc and it will pre-fill this information whenever possible.
 */
@interface STPUserInformation : NSObject<NSCopying>

/**
 *  The user's email address.
 */
@property(nonatomic, copy, nullable)NSString *email;

/**
 *  The user's phone number. When set, this property will automatically strip out any non-numeric characters from the string you specify.
 */
@property(nonatomic, copy, nullable)NSString *phone;

/**
 *  The user's billing address. When set, the add card form will be filled with this address.
 *  The user will also have the option to fill their shipping address using this address.
 */
@property(nonatomic, strong, nullable)STPAddress *billingAddress;

@end

NS_ASSUME_NONNULL_END
