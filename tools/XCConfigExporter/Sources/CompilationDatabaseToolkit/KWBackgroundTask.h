#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN;

@interface KWBackgroundTask : NSObject

@property (readonly) int terminationStatus;
@property (nonatomic, readonly) NSString *command;
@property (nonatomic, readonly) NSArray *arguments;
@property (nonatomic, readonly) NSData *standardOutputData;
@property (nonatomic, readonly) NSData *standardErrorData;

- (instancetype)initWithCommand:(NSString *)command arguments:(NSArray *)arguments timeout:(NSTimeInterval)timeout;

- (void)launchAndWaitForExit;

@end

NS_ASSUME_NONNULL_END;
