//
//  STPAddressTests.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PassKit/PassKit.h>
#import <Contacts/Contacts.h>
#import "STPAddress.h"
#import "STPFixtures.h"

@interface STPAddressTests : XCTestCase

@end

@implementation STPAddressTests

- (void)testInitWithPKContact_complete {

    PKContact *contact = [PKContact new];
    {
        NSPersonNameComponents *name = [NSPersonNameComponents new];
        name.givenName = @"John";
        name.familyName = @"Doe";
        contact.name = name;

        contact.emailAddress = @"foo@example.com";
        contact.phoneNumber = [CNPhoneNumber phoneNumberWithStringValue:@"888-555-1212"];

        CNMutablePostalAddress *address = [CNMutablePostalAddress new];
        address.street = @"55 John St";
        address.city = @"New York";
        address.state = @"NY";
        address.postalCode = @"10002";
        address.ISOCountryCode = @"US";
        address.country = @"United States";
        contact.postalAddress = address.copy;
    }

    STPAddress *address = [[STPAddress alloc] initWithPKContact:contact];
    XCTAssertEqualObjects(@"John Doe", address.name);
    XCTAssertEqualObjects(@"8885551212", address.phone);
    XCTAssertEqualObjects(@"foo@example.com", address.email);
    XCTAssertEqualObjects(@"55 John St", address.line1);
    XCTAssertEqualObjects(@"New York", address.city);
    XCTAssertEqualObjects(@"NY", address.state);
    XCTAssertEqualObjects(@"10002", address.postalCode);
    XCTAssertEqualObjects(@"US", address.country);
}

- (void)testInitWithPKContact_partial {
    PKContact *contact = [PKContact new];
    {
        NSPersonNameComponents *name = [NSPersonNameComponents new];
        name.givenName = @"John";
        contact.name = name;

        CNMutablePostalAddress *address = [CNMutablePostalAddress new];
        address.state = @"VA";
        contact.postalAddress = address.copy;
    }

    STPAddress *address = [[STPAddress alloc] initWithPKContact:contact];
    XCTAssertEqualObjects(@"John", address.name);
    XCTAssertNil(address.phone);
    XCTAssertNil(address.email);
    XCTAssertNil(address.line1);
    XCTAssertNil(address.city);
    XCTAssertEqualObjects(@"VA", address.state);
    XCTAssertNil(address.postalCode);
    XCTAssertNil(address.country);
}

- (void)testInitWithCNContact_complete {
    if ([CNContact class] == nil) {
        // Method not supported by iOS version
        return;
    }

    CNMutableContact *contact = [CNMutableContact new];
    {
        contact.givenName = @"John";
        contact.familyName = @"Doe";

        contact.emailAddresses = @[
                                   [CNLabeledValue labeledValueWithLabel:CNLabelHome
                                                                   value:@"foo@example.com"],
                                   [CNLabeledValue labeledValueWithLabel:CNLabelWork
                                                                   value:@"bar@example.com"],


                                   ];

        contact.phoneNumbers = @[
                                 [CNLabeledValue labeledValueWithLabel:CNLabelHome
                                                                 value:[CNPhoneNumber phoneNumberWithStringValue:@"888-555-1212"]],
                                 [CNLabeledValue labeledValueWithLabel:CNLabelWork
                                                                 value:[CNPhoneNumber phoneNumberWithStringValue:@"555-555-5555"]],


                                 ];

        CNMutablePostalAddress *address = [CNMutablePostalAddress new];
        address.street = @"55 John St";
        address.city = @"New York";
        address.state = @"NY";
        address.postalCode = @"10002";
        address.ISOCountryCode = @"US";
        address.country = @"United States";
        contact.postalAddresses = @[
                                    [CNLabeledValue labeledValueWithLabel:CNLabelHome
                                                                    value:address],
                                    ];
    }

    STPAddress *address = [[STPAddress alloc] initWithCNContact:contact];
    XCTAssertEqualObjects(@"John Doe", address.name);
    XCTAssertEqualObjects(@"8885551212", address.phone);
    XCTAssertEqualObjects(@"foo@example.com", address.email);
    XCTAssertEqualObjects(@"55 John St", address.line1);
    XCTAssertEqualObjects(@"New York", address.city);
    XCTAssertEqualObjects(@"NY", address.state);
    XCTAssertEqualObjects(@"10002", address.postalCode);
    XCTAssertEqualObjects(@"US", address.country);
}

- (void)testInitWithCNContact_partial {
    if ([CNContact class] == nil) {
        // Method not supported by iOS version
        return;
    }

    CNMutableContact *contact = [CNMutableContact new];
    {
        contact.givenName = @"John";

        CNMutablePostalAddress *address = [CNMutablePostalAddress new];
        address.state = @"VA";
        contact.postalAddresses = @[
                                    [CNLabeledValue labeledValueWithLabel:CNLabelHome
                                                                    value:address],
                                    ];
    }

    STPAddress *address = [[STPAddress alloc] initWithCNContact:contact];
    XCTAssertEqualObjects(@"John", address.name);
    XCTAssertNil(address.phone);
    XCTAssertNil(address.email);
    XCTAssertNil(address.line1);
    XCTAssertNil(address.city);
    XCTAssertEqualObjects(@"VA", address.state);
    XCTAssertNil(address.postalCode);
    XCTAssertNil(address.country);
}

- (void)testPKContactValue {
    STPAddress *address = [STPAddress new];
    address.name = @"John Smith Doe";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";

    PKContact *contact = [address PKContactValue];
    XCTAssertEqualObjects(contact.name.givenName, @"John");
    XCTAssertEqualObjects(contact.name.familyName, @"Smith Doe");
    XCTAssertEqualObjects(contact.phoneNumber.stringValue, @"8885551212");
    XCTAssertEqualObjects(contact.emailAddress, @"foo@example.com");
    CNPostalAddress *postalAddress = contact.postalAddress;
    XCTAssertEqualObjects(postalAddress.street, @"55 John St");
    XCTAssertEqualObjects(postalAddress.city, @"New York");
    XCTAssertEqualObjects(postalAddress.state, @"NY");
    XCTAssertEqualObjects(postalAddress.postalCode, @"10002");
    XCTAssertEqualObjects(postalAddress.country, @"US");
}

- (void)testContainsRequiredFieldsNone {
    STPAddress *address = [STPAddress new];
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsNone]);
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.name = @"John Doe";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsNone]);
    address.country = @"UK";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsNone]);
}


- (void)testContainsRequiredFieldsZip {
    STPAddress *address = [STPAddress new];

    // nil country is treated as generic postal requirement
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = @"IE"; //should pass for country which doesn't require zip/postal
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = @"US";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.postalCode = @"10002";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.postalCode = @"ABCDE";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = @"UK"; // should pass for alphanumeric countries
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = nil; // nil treated as alphanumeric
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
}
- (void)testContainsRequiredFieldsFull {
    STPAddress *address = [STPAddress new];
    
    /**
     Required fields for full are:
     line1, city, country, state (US only) and a valid postal code (based on country)
     */
    
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.country = @"US";
    address.line1 = @"55 John St";
    
    // Fail on partial 
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    
    address.city = @"New York";
    
    // For US fail if missing state or zip
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.state = @"NY";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.postalCode = @"ABCDE";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    //postal must be numeric for US
    address.postalCode = @"10002";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.name = @"John Doe";
    // Name/phone/email should have no effect
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    
    // Non US countries don't require state
    address.country = @"UK";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.state = nil;
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    // alphanumeric postal ok in some countries
    address.postalCode = @"ABCDE";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    // UK requires ZIP
    address.postalCode = nil;
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    
    
    address.country = @"IE"; // Doesn't require postal or state, but allows them
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.postalCode = @"ABCDE";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.state = @"Test";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
}

- (void)testContainsContentForBillingAddressFields {
    STPAddress *address = [STPAddress new];

    // Empty address should return false for everything
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsNone]);
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsZip]);
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsFull]);

    // 1+ characters in postalCode will return true for .Zip && .Full
    address.postalCode = @"0";
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsNone]);
    XCTAssertTrue([address containsContentForBillingAddressFields:STPBillingAddressFieldsZip]);
    XCTAssertTrue([address containsContentForBillingAddressFields:STPBillingAddressFieldsFull]);
    // empty string returns false
    address.postalCode = @"";
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsNone]);
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsZip]);
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsFull]);
    address.postalCode = nil;

    // Test every other property that contributes to the full address, ensuring it returns True for .Full only
    // This is *not* refactoring-safe, but I think it's better than a bunch of duplicated code
    for (NSString *propertyName in @[@"line1", @"line2", @"city", @"state", @"country"]) {
        for (NSString *testValue in @[@"a", @"0", @"Foo Bar"]) {
            [address setValue:testValue forKey:propertyName];
            XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsNone]);
            XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsZip]);
            XCTAssertTrue([address containsContentForBillingAddressFields:STPBillingAddressFieldsFull]);
            [address setValue:nil forKey:propertyName];
        }

        // Make sure that empty string is treated like nil, and returns false for these properties
        [address setValue:@"" forKey:propertyName];
        XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsNone]);
        XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsZip]);
        XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsFull]);
        [address setValue:nil forKey:propertyName];
    }

    // ensure it still returns false for everything since it has been cleared
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsNone]);
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsZip]);
    XCTAssertFalse([address containsContentForBillingAddressFields:STPBillingAddressFieldsFull]);
}

- (void)testContainsRequiredShippingAddressFields {
    STPAddress *address = [STPAddress new];
    XCTAssertTrue([address containsRequiredShippingAddressFields:nil]);
    NSSet<STPContactField> *allFields = [NSSet setWithArray:@[STPContactFieldPostalAddress,
                                                              STPContactFieldEmailAddress,
                                                              STPContactFieldPhoneNumber,
                                                              STPContactFieldName]];
    XCTAssertFalse([address containsRequiredShippingAddressFields:allFields]);

    address.name = @"John Smith";
    XCTAssertTrue(([address containsRequiredShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
    XCTAssertFalse(([address containsRequiredShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));

    address.email = @"john@example.com";
    XCTAssertTrue(([address containsRequiredShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName, STPContactFieldEmailAddress]]]));
    XCTAssertFalse(([address containsRequiredShippingAddressFields:allFields]));

    address.phone = @"5555555555";
    XCTAssertTrue(([address containsRequiredShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName, STPContactFieldEmailAddress, STPContactFieldPhoneNumber]]]));
    address.phone = @"555";
    XCTAssertFalse(([address containsRequiredShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName, STPContactFieldEmailAddress, STPContactFieldPhoneNumber]]]));
    XCTAssertFalse(([address containsRequiredShippingAddressFields:allFields]));
    address.country = @"GB";
    XCTAssertTrue(([address containsRequiredShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName, STPContactFieldEmailAddress, STPContactFieldPhoneNumber]]]));

    address.country = @"US";
    address.phone = @"5555555555";
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"12345";
    XCTAssertTrue([address containsRequiredShippingAddressFields:allFields]);
}

- (void)testContainsContentForShippingAddressFields {
    STPAddress *address = [STPAddress new];

    // Empty address should return false for everything
    XCTAssertFalse(([address containsContentForShippingAddressFields:nil]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress]]]));

    // Name
    address.name = @"Smith";
    XCTAssertFalse(([address containsContentForShippingAddressFields:nil]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress]]]));
    address.name = @"";

    // Phone
    address.phone = @"1";
    XCTAssertFalse(([address containsContentForShippingAddressFields:nil]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress]]]));
    address.phone = @"";

    // Email
    address.email = @"f";
    XCTAssertFalse(([address containsContentForShippingAddressFields:nil]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber]]]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress]]]));
    address.email = @"";

    // Test every property that contributes to the full address
    // This is *not* refactoring-safe, but I think it's better than a bunch more duplicated code
    for (NSString *propertyName in @[@"line1", @"line2", @"city", @"state", @"postalCode", @"country"]) {
        for (NSString *testValue in @[@"a", @"0", @"Foo Bar"]) {
            [address setValue:testValue forKey:propertyName];
            XCTAssertFalse(([address containsContentForShippingAddressFields:nil]));
            XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
            XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber]]]));
            XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));
            XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress]]]));
            [address setValue:@"" forKey:propertyName];
        }
    }

    // ensure it still returns false for everything with empty strings
    XCTAssertFalse(([address containsContentForShippingAddressFields:nil]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress]]]));

    // Try a hybrid address, and make sure some bitwise combinations work
    address.name = @"a";
    address.phone = @"1";
    address.line1 = @"_";
    XCTAssertFalse(([address containsContentForShippingAddressFields:nil]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName]]]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber]]]));
    XCTAssertFalse(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldEmailAddress]]]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress]]]));

    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldName, STPContactFieldEmailAddress]]]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPhoneNumber, STPContactFieldEmailAddress]]]));
    XCTAssertTrue(([address containsContentForShippingAddressFields:[NSSet setWithArray:@[STPContactFieldPostalAddress,
                                                                                          STPContactFieldEmailAddress,
                                                                                          STPContactFieldPhoneNumber,
                                                                                          STPContactFieldName]]]));

}


- (void)testShippingInfoForCharge {
    STPAddress *address = [STPFixtures address];
    PKShippingMethod *method = [[PKShippingMethod alloc] init];
    method.label = @"UPS Ground";
    NSDictionary *info = [STPAddress shippingInfoForChargeWithAddress:address
                                                       shippingMethod:method];
    NSDictionary *expected = @{
                               @"address": @{
                                       @"city": address.city,
                                       @"country": address.country,
                                       @"line1": address.line1,
                                       @"line2": address.line2,
                                       @"postal_code": address.postalCode,
                                       @"state": address.state
                                       },
                               @"name": address.name,
                               @"phone": address.phone,
                               @"carrier": method.label,
                               };
    XCTAssertEqualObjects(expected, info);
}

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertNil([STPAddress rootObjectName]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPAddress *address = [STPAddress new];

    NSDictionary *mapping = [STPAddress propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([address respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end
