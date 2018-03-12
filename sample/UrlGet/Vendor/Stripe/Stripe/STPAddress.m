//
//  STPAddress.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "NSDictionary+Stripe.h"
#import "STPAddress.h"
#import "STPCardValidator.h"
#import "STPEmailAddressValidator.h"
#import "STPPhoneNumberValidator.h"
#import "STPPostalCodeValidator.h"

#define FAUXPAS_IGNORED_IN_FILE(...)
FAUXPAS_IGNORED_IN_FILE(APIAvailability)

@interface STPAddress ()

@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPAddress

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

- (instancetype)initWithABRecord:(ABRecordRef)record {
    self = [super init];
    if (self) {
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
        NSString *first = firstName ?: @"";
        NSString *last = lastName ?: @"";
        NSString *name = [@[first, last] componentsJoinedByString:@" "];
        _name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        ABMultiValueRef emailValues = ABRecordCopyValue(record, kABPersonEmailProperty);
        _email = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(emailValues, 0));
        if (emailValues != NULL) {
            CFRelease(emailValues);
        }
        
        ABMultiValueRef phoneValues = ABRecordCopyValue(record, kABPersonPhoneProperty);
        NSString *phone = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(phoneValues, 0));
        if (phoneValues != NULL) {
            CFRelease(phoneValues);
        }
        phone = [STPCardValidator sanitizedNumericStringForString:phone];
        if ([phone length] > 0) {
            _phone = phone;
        }

        ABMultiValueRef addressValues = ABRecordCopyValue(record, kABPersonAddressProperty);
        if (addressValues != NULL) {
            if (ABMultiValueGetCount(addressValues) > 0) {
                CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
                NSString *street = CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
                if (street) {
                    _line1 = street;
                }
                NSString *city = CFDictionaryGetValue(dict, kABPersonAddressCityKey);
                if (city) {
                    _city = city;
                }
                NSString *state = CFDictionaryGetValue(dict, kABPersonAddressStateKey);
                if (state) {
                    _state = state;
                }
                NSString *zip = CFDictionaryGetValue(dict, kABPersonAddressZIPKey);
                if (zip) {
                    _postalCode = zip;
                }
                NSString *country = CFDictionaryGetValue(dict, kABPersonAddressCountryCodeKey);
                if (country) {
                    _country = [country uppercaseString];
                }
                if (dict != NULL) {
                    CFRelease(dict);
                }
            }
            CFRelease(addressValues);
        }
    }
    return self;
}

- (ABRecordRef)ABRecordValue {
    ABRecordRef record = ABPersonCreate();
    if ([self firstName] != nil) {
        CFStringRef firstNameRef = (__bridge CFStringRef)[self firstName];
        ABRecordSetValue(record, kABPersonFirstNameProperty, firstNameRef, nil);
    }
    if ([self lastName] != nil) {
        CFStringRef lastNameRef = (__bridge CFStringRef)[self lastName];
        ABRecordSetValue(record, kABPersonLastNameProperty, lastNameRef, nil);
    }
    if (self.phone != nil) {
        ABMutableMultiValueRef phonesRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(phonesRef, (__bridge CFStringRef)self.phone,
                                     kABPersonPhoneMainLabel, NULL);
        ABRecordSetValue(record, kABPersonPhoneProperty, phonesRef, nil);
        CFRelease(phonesRef);
    }
    if (self.email != nil) {
        ABMutableMultiValueRef emailsRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(emailsRef, (__bridge CFStringRef)self.email,
                                     kABHomeLabel, NULL);
        ABRecordSetValue(record, kABPersonEmailProperty, emailsRef, nil);
        CFRelease(emailsRef);
    }
    ABMutableMultiValueRef addressRef = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    addressDict[(NSString *)kABPersonAddressStreetKey] = [self street];
    addressDict[(NSString *)kABPersonAddressCityKey] = self.city;
    addressDict[(NSString *)kABPersonAddressStateKey] = self.state;
    addressDict[(NSString *)kABPersonAddressZIPKey] = self.postalCode;
    addressDict[(NSString *)kABPersonAddressCountryCodeKey] = self.country;
    ABMultiValueAddValueAndLabel(addressRef, (__bridge CFTypeRef)[addressDict copy], kABWorkLabel, NULL);
    ABRecordSetValue(record, kABPersonAddressProperty, addressRef, nil);
    CFRelease(addressRef);
    return CFAutorelease(record);
}

#pragma clang diagnostic pop

- (PKContact *)PKContactValue {
    PKContact *contact = [PKContact new];
    NSPersonNameComponents *name = [NSPersonNameComponents new];
    name.givenName = [self firstName];
    name.familyName = [self lastName];
    contact.name = name;
    contact.emailAddress = self.email;
    CNMutablePostalAddress *address = [CNMutablePostalAddress new];
    address.street = [self street];
    address.city = self.city;
    address.state = self.state;
    address.postalCode = self.postalCode;
    address.country = self.country;
    contact.postalAddress = address;
    contact.phoneNumber = [CNPhoneNumber phoneNumberWithStringValue:self.phone];
    return contact;
}

- (NSString *)firstName {
    NSArray<NSString *>*components = [self.name componentsSeparatedByString:@" "];
    return [components firstObject];
}

- (NSString *)lastName {
    NSArray<NSString *>*components = [self.name componentsSeparatedByString:@" "];
    NSString *firstName = [components firstObject];
    NSString *lastName = [self.name stringByReplacingOccurrencesOfString:firstName withString:@""];
    lastName = [lastName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([lastName length] == 0) {
        lastName = nil;
    }
    return lastName;
}

- (NSString *)street {
    NSString *street = nil;
    if (self.line1 != nil) {
        street = [@"" stringByAppendingString:self.line1];
    }
    if (self.line2 != nil) {
        street = [@[street ?: @"", self.line2] componentsJoinedByString:@" "];
    }
    return street;
}

- (BOOL)containsRequiredFields:(STPBillingAddressFields)requiredFields {
    BOOL containsFields = YES;
    switch (requiredFields) {
        case STPBillingAddressFieldsNone:
            return YES;
        case STPBillingAddressFieldsZip:
            return [STPPostalCodeValidator stringIsValidPostalCode:self.postalCode 
                                                       countryCode:self.country];
        case STPBillingAddressFieldsFull:
            return [self hasValidPostalAddress];
    }
    return containsFields;
}

- (BOOL)containsRequiredShippingAddressFields:(PKAddressField)requiredFields {
    BOOL containsFields = YES;
    if (requiredFields & PKAddressFieldName) {
        containsFields = containsFields && [self.name length] > 0;
    }
    if (requiredFields & PKAddressFieldEmail) {
        containsFields = containsFields && [STPEmailAddressValidator stringIsValidEmailAddress:self.email];
    }
    if (requiredFields & PKAddressFieldPhone) {
        containsFields = containsFields && [STPPhoneNumberValidator stringIsValidPhoneNumber:self.phone forCountryCode:self.country];
    }
    if (requiredFields & PKAddressFieldPostalAddress) {
        containsFields = containsFields && [self hasValidPostalAddress];
    }
    return containsFields;
}

- (BOOL)hasValidPostalAddress {
    return (self.line1.length > 0 
            && self.city.length > 0 
            && self.country.length > 0 
            && (self.state.length > 0 || ![self.country isEqualToString:@"US"])  
            && [STPPostalCodeValidator stringIsValidPostalCode:self.postalCode 
                                                   countryCode:self.country]);
}

+ (PKAddressField)applePayAddressFieldsFromBillingAddressFields:(STPBillingAddressFields)billingAddressFields {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    switch (billingAddressFields) {
        case STPBillingAddressFieldsNone:
            return PKAddressFieldNone;
        case STPBillingAddressFieldsZip:
        case STPBillingAddressFieldsFull:
            return PKAddressFieldPostalAddress;
    }
}

#pragma mark STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPAddress *address = [self new];
    address.allResponseFields = dict;
    address.city = dict[@"city"];
    address.country = dict[@"country"];
    address.line1 = dict[@"line1"];
    address.line2 = dict[@"line2"];
    address.postalCode = dict[@"postal_code"];
    address.state = dict[@"state"];
    return address;
}

@end

