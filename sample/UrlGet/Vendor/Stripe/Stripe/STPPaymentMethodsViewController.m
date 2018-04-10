//
//  STPPaymentMethodsViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsViewController.h"

#import "STPAPIClient.h"
#import "STPAddCardViewController+Private.h"
#import "STPCard.h"
#import "STPColorUtils.h"
#import "STPCoreViewController+Private.h"
#import "STPCustomer+SourceTuple.h"
#import "STPDispatchFunctions.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentActivityIndicatorView.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "STPPaymentContext.h"
#import "STPPaymentMethodTuple.h"
#import "STPPaymentMethodsInternalViewController.h"
#import "STPPaymentMethodsViewController+Private.h"
#import "STPSource.h"
#import "STPTheme.h"
#import "STPToken.h"
#import "STPWeakStrongMacros.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

@interface STPPaymentMethodsViewController()<STPPaymentMethodsInternalViewControllerDelegate, STPAddCardViewControllerDelegate>

@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) id<STPBackendAPIAdapter> apiAdapter;
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPPromise<STPPaymentMethodTuple *> *loadingPromise;
@property (nonatomic, weak) STPPaymentActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) UIViewController *internalViewController;
@property (nonatomic) BOOL loading;

@end

@implementation STPPaymentMethodsViewController

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext {
    return [self initWithConfiguration:paymentContext.configuration
                            apiAdapter:paymentContext.apiAdapter
                        loadingPromise:paymentContext.currentValuePromise
                                 theme:paymentContext.theme
                       shippingAddress:paymentContext.shippingAddress
                              delegate:paymentContext];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                      customerContext:(STPCustomerContext *)customerContext
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate {
    return [self initWithConfiguration:configuration theme:theme apiAdapter:customerContext delegate:delegate];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate {
    STPPromise<STPPaymentMethodTuple *> *promise = [self retrieveCustomerWithConfiguration:configuration apiAdapter:apiAdapter];
    return [self initWithConfiguration:configuration
                            apiAdapter:apiAdapter
                        loadingPromise:promise
                                 theme:theme
                       shippingAddress:nil
                              delegate:delegate];
}

- (STPPromise<STPPaymentMethodTuple *>*)retrieveCustomerWithConfiguration:(STPPaymentConfiguration *)configuration
                                                               apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter {
    STPPromise<STPPaymentMethodTuple *> *promise = [STPPromise new];
    [apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable error) {
        stpDispatchToMainThreadIfNecessary(^{
            if (error) {
                [promise fail:error];
            } else {
                STPPaymentMethodTuple *paymentTuple = [customer filteredSourceTupleForUIWithConfiguration:configuration];
                [promise succeed:paymentTuple];
            }
        });
    }];
    return promise;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    STPPaymentActivityIndicatorView *activityIndicator = [STPPaymentActivityIndicatorView new];
    activityIndicator.animating = YES;
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;

    WEAK(self);
    [self.loadingPromise onSuccess:^(STPPaymentMethodTuple *tuple) {
        STRONG(self);
        if (!self) {
            return;
        }
        UIViewController *internal;
        if (tuple.paymentMethods.count > 0) {
            STPCustomerContext *customerContext = ([self.apiAdapter isKindOfClass:[STPCustomerContext class]]) ? (STPCustomerContext *)self.apiAdapter : nil;

            STPPaymentMethodsInternalViewController *payMethodsInternal = [[STPPaymentMethodsInternalViewController alloc] initWithConfiguration:self.configuration
                                                                                                                                 customerContext:customerContext
                                                                                                                                           theme:self.theme
                                                                                                                            prefilledInformation:self.prefilledInformation
                                                                                                                                 shippingAddress:self.shippingAddress
                                                                                                                              paymentMethodTuple:tuple
                                                                                                                                        delegate:self];
            payMethodsInternal.createsCardSources = self.configuration.createCardSources;
            if (self.paymentMethodsViewControllerFooterView) {
                payMethodsInternal.customFooterView = self.paymentMethodsViewControllerFooterView;
            }
            internal = payMethodsInternal;
        }
        else {
            STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
            addCardViewController.delegate = self;
            addCardViewController.prefilledInformation = self.prefilledInformation;
            addCardViewController.shippingAddress = self.shippingAddress;
            internal = addCardViewController;

            if (self.addCardViewControllerFooterView) {
                addCardViewController.customFooterView = self.addCardViewControllerFooterView;

            }
        }
        
        internal.stp_navigationItemProxy = self.navigationItem;
        [self addChildViewController:internal];
        internal.view.alpha = 0;
        [self.view insertSubview:internal.view belowSubview:self.activityIndicator];
        [self.view addSubview:internal.view];
        internal.view.frame = self.view.bounds;
        [internal didMoveToParentViewController:self];
        [UIView animateWithDuration:0.2 animations:^{
            self.activityIndicator.alpha = 0;
            internal.view.alpha = 1;
        } completion:^(__unused BOOL finished) {
            self.activityIndicator.animating = NO;
        }];
        [self.navigationItem setRightBarButtonItem:internal.stp_navigationItemProxy.rightBarButtonItem animated:YES];
        self.internalViewController = internal;
    }];
    self.loading = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat centerX = (self.view.frame.size.width - self.activityIndicator.frame.size.width) / 2;
    CGFloat centerY = (self.view.frame.size.height - self.activityIndicator.frame.size.height) / 2;
    self.activityIndicator.frame = CGRectMake(centerX, centerY, self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
    self.internalViewController.view.frame = self.view.bounds;
}

- (void)updateAppearance {
    [super updateAppearance];

    self.activityIndicator.tintColor = self.theme.accentColor;
}

- (void)finishWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    BOOL methodIsCardToken = [paymentMethod isKindOfClass:[STPCard class]];
    BOOL methodIsCardSource = ([paymentMethod isKindOfClass:[STPSource class]] &&
                               ((STPSource *)paymentMethod).type == STPSourceTypeCard);
    id<STPSourceProtocol> source;
    if (methodIsCardToken) {
        source = (STPCard *)paymentMethod;
    }
    else if (methodIsCardSource) {
        source = (STPSource *)paymentMethod;
    }
    if (source) {
        // Make this payment method the default source
        [self.apiAdapter selectDefaultCustomerSource:source completion:^(__unused NSError *error) {
            // Reload the internal payment methods view controller with the updated customer
            STPPromise<STPPaymentMethodTuple *> *promise = [self retrieveCustomerWithConfiguration:self.configuration apiAdapter:self.apiAdapter];
            [promise onSuccess:^(STPPaymentMethodTuple *tuple) {
                stpDispatchToMainThreadIfNecessary(^{
                    if ([self.internalViewController isKindOfClass:[STPPaymentMethodsInternalViewController class]]) {
                        STPPaymentMethodsInternalViewController *paymentMethodsVC = (STPPaymentMethodsInternalViewController *)self.internalViewController;
                        [paymentMethodsVC updateWithPaymentMethodTuple:tuple];
                    }
                });
            }];
        }];
    }
    if ([self.delegate respondsToSelector:@selector(paymentMethodsViewController:didSelectPaymentMethod:)]) {
        [self.delegate paymentMethodsViewController:self didSelectPaymentMethod:paymentMethod];
    }
    [self.delegate paymentMethodsViewControllerDidFinish:self];
}

- (void)internalViewControllerDidSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    [self finishWithPaymentMethod:paymentMethod];
}

- (void)internalViewControllerDidDeletePaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    if ([self.delegate isKindOfClass:[STPPaymentContext class]]) {
        // Notify payment context to update its copy of payment methods
        STPPaymentContext *paymentContext = (STPPaymentContext *)self.delegate;
        [paymentContext removePaymentMethod:paymentMethod];
    }
}

- (void)internalViewControllerDidCreateSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    [self.apiAdapter attachSourceToCustomer:source completion:^(NSError *error) {
        stpDispatchToMainThreadIfNecessary(^{
            completion(error);
            if (!error) {
                /**
                 When createCardSources is false, the SDK:
                 1. Sends the token to customers/[id]/sources. This
                 adds token.card to the customer's sources list. Surprisingly,
                 attaching token.card to the customer will fail.
                 2. Returns token.card to didCreatePaymentResult,
                 where the user tells their backend to create a charge.
                 A charge request with the token ID and customer ID
                 will fail because the token is not linked to the
                 customer (the card is).
                 */
                if ([source isKindOfClass:[STPToken class]]) {
                    [self finishWithPaymentMethod:((STPToken *)source).card];
                }
                // created a card source
                else if ([source isKindOfClass:[STPSource class]] &&
                         ((STPSource *)source).type == STPSourceTypeCard) {
                    [self finishWithPaymentMethod:(id<STPPaymentMethod>)source];
                }
            }
        });
    }];
}

- (void)internalViewControllerDidCancel {
    [self.delegate paymentMethodsViewControllerDidCancel:self];
}

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    // Add card is only our direct delegate if there are no other payment methods possible
    // and we skipped directly to this screen. In this case, a cancel from it is the same as a cancel to us.
    [self.delegate paymentMethodsViewControllerDidCancel:self];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion {
    [self internalViewControllerDidCreateSource:token completion:completion];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
              didCreateSource:(STPSource *)source
                   completion:(STPErrorBlock)completion {
    [self internalViewControllerDidCreateSource:source completion:completion];
}

- (void)dismissWithCompletion:(STPVoidBlock)completion {
    if ([self stp_isAtRootOfNavigationController]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:completion];
    }
    else {
        UIViewController *previous = self.navigationController.viewControllers.firstObject;
        for (UIViewController *viewController in self.navigationController.viewControllers) {
            if (viewController == self) {
                break;
            }
            previous = viewController;
        }
        [self.navigationController stp_popToViewController:previous animated:YES completion:completion];
    }
}

@end

@implementation STPPaymentMethodsViewController (Private)

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                       loadingPromise:(STPPromise<STPPaymentMethodTuple *> *)loadingPromise
                                theme:(STPTheme *)theme
                      shippingAddress:(STPAddress *)shippingAddress
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate {
    self = [super initWithTheme:theme];
    if (self) {
        _configuration = configuration;
        _shippingAddress = shippingAddress;
        _apiClient = [[STPAPIClient alloc] initWithPublishableKey:configuration.publishableKey];
        _apiAdapter = apiAdapter;
        _loadingPromise = loadingPromise;
        _delegate = delegate;

        self.navigationItem.title = STPLocalizedString(@"Loading…", @"Title for screen when data is still loading from the network.");

        WEAK(self);
        [[[self.stp_didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
            return loadingPromise;
        }] onSuccess:^(STPPaymentMethodTuple *tuple) {
            STRONG(self);
            if (!self) {
                return;
            }

            if (tuple.selectedPaymentMethod) {
                if ([self.delegate respondsToSelector:@selector(paymentMethodsViewController:didSelectPaymentMethod:)]) {
                    [self.delegate paymentMethodsViewController:self
                                         didSelectPaymentMethod:tuple.selectedPaymentMethod];
                }
            }
        }] onFailure:^(NSError *error) {
            STRONG(self);
            if (!self) {
                return;
            }

            [self.delegate paymentMethodsViewController:self didFailToLoadWithError:error];
        }];
    }
    return self;
}

@end
