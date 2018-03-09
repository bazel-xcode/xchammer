#import <Foundation/Foundation.h>

@implementation PINFoo : NSObject
+ (void)foo
{
  NSNumber *foo = [[NSNumber alloc] init];
  [foo retain];
  [foo release];
  [foo release];
}
@end

