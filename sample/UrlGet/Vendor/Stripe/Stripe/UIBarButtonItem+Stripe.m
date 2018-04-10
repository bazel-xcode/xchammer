//
//  UIBarButtonItem+Stripe.m
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIBarButtonItem+Stripe.h"

#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPTheme.h"

@implementation UIBarButtonItem (Stripe)

- (void)stp_setTheme:(STPTheme *)theme {
    UIImage *image = [self backgroundImageForState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    if (image) {
        UIImage *enabledImage = [STPImageLibrary imageWithTintColor:theme.accentColor forImage:image];
        UIImage *disabledImage = [STPImageLibrary imageWithTintColor:theme.secondaryForegroundColor forImage:image];
        [self setBackgroundImage:enabledImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self setBackgroundImage:disabledImage forState:UIControlStateDisabled barMetrics:UIBarMetricsDefault];
    }
    
    self.tintColor = self.enabled ? theme.accentColor : theme.secondaryForegroundColor;
    [self setTitleTextAttributes:@{
                                   NSFontAttributeName: self.style == UIBarButtonItemStylePlain ? theme.font : theme.emphasisFont,
                                   NSForegroundColorAttributeName: theme.accentColor,
                                   }
                        forState:UIControlStateNormal];
    [self setTitleTextAttributes:@{
                                   NSFontAttributeName: self.style == UIBarButtonItemStylePlain ? theme.font : theme.emphasisFont,
                                   NSForegroundColorAttributeName: theme.secondaryForegroundColor,
                                   }
                        forState:UIControlStateDisabled];
}

@end

void linkUIBarButtonItemCategory(void){}

