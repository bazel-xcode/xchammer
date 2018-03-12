//
//  STPPaymentContextAmountModel.h
//  Stripe
//
//  Created by Brian Dorfman on 8/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

#define FAUXPAS_IGNORED_IN_CLASS(...)

/**
 Internal model for STPPaymentContext's `paymentAmount` and 
 `paymentSummaryItems` properties.
 */
@interface STPPaymentContextAmountModel : NSObject
FAUXPAS_IGNORED_IN_CLASS(APIAvailability)

- (instancetype)initWithAmount:(NSInteger)paymentAmount;
- (instancetype)initWithPaymentSummaryItems:(NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems;

- (NSInteger)paymentAmountWithCurrency:(NSString *)currency
                        shippingMethod:(PKShippingMethod *)shippingMethod;
- (NSArray<PKPaymentSummaryItem *> *)paymentSummaryItemsWithCurrency:(NSString *)currency
                                                         companyName:(NSString *)companyName
                                                      shippingMethod:(PKShippingMethod *)shippingMethod;

@end
