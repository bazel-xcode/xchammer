//
//  STPEphemeralKey.m
//  Stripe
//
//  Created by Ben Guo on 5/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPEphemeralKey.h"

#import "NSDictionary+Stripe.h"

@interface STPEphemeralKey ()

@property (nonatomic, readwrite) NSString *stripeID;
@property (nonatomic, readwrite) NSDate *created;
@property (nonatomic, readwrite) BOOL livemode;
@property (nonatomic, readwrite) NSString *secret;
@property (nonatomic, readwrite) NSDate *expires;
@property (nonatomic, readwrite) NSString *customerID;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPEphemeralKey

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    // required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    NSDate *created = [dict stp_dateForKey:@"created"];
    NSString *secret = [dict stp_stringForKey:@"secret"];
    NSDate *expires = [dict stp_dateForKey:@"expires"];
    NSArray *associatedObjects = [dict stp_arrayForKey:@"associated_objects"];
    if (!stripeId || !created || !secret || !expires || !associatedObjects || !dict[@"livemode"]) {
        return nil;
    }

    NSString *customerID;
    for (id obj in associatedObjects) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSString *type = [obj stp_stringForKey:@"type"];
            if ([type isEqualToString:@"customer"]) {
                customerID = [obj stp_stringForKey:@"id"];
            }
        }
    }
    if (!customerID) {
        return nil;
    }
    STPEphemeralKey *key = [self new];
    key.customerID = customerID;
    key.stripeID = stripeId;
    key.livemode = [dict stp_boolForKey:@"livemode" or:YES];
    key.created = created;
    key.secret = secret;
    key.expires = expires;
    key.allResponseFields = dict;
    return key;
}

- (NSUInteger)hash {
    return [self.stripeID hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (!object || ![object isKindOfClass:self.class]) {
        return NO;
    }
    return [self isEqualToResourceKey:object];
}

- (BOOL)isEqualToResourceKey:(STPEphemeralKey *)other {
    return [self.stripeID isEqualToString:other.stripeID] 
        && [self.secret isEqualToString:other.secret]
        && [self.expires isEqual:other.expires]
        && [self.customerID isEqual:other.customerID];
}

@end
