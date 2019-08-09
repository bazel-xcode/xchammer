//
// Licensed under the terms in License.txt
//
// Copyright 2010 Allen Ding. All rights reserved.
//
// This file is licensed under a BSD equivalent license.

#import "KWBackgroundTask.h"

NSString *const NSTaskDidTerminateNotification;

static NSString *const KWTaskDidTerminateNotification = @"KWTaskDidTerminateNotification";

static NSString *const KWBackgroundTaskException = @"KWBackgroundTaskException";

@implementation KWBackgroundTask
{
    NSData *_standardOutputData;
    NSData *_standardErrorData;
    NSPipe *_standardOutput;
    NSPipe *_standardError;
    NSTimeInterval _timeout;
    NSTask *_task;
}

- (instancetype)initWithCommand:(NSString *)command arguments:(NSArray *)arguments timeout:(NSTimeInterval)timeout {
    if (self = [super init]) {
        _command = command;
        _arguments = arguments;
        _timeout = timeout;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ `%@ %@`", [super description], self.command, [self.arguments componentsJoinedByString:@" "]];
}

// Run this task until _timeout is hit.
// If it times out raise an exception
- (void)launchAndWaitForExit {
    CFRunLoopRef runLoop = [NSRunLoop currentRunLoop].getCFRunLoop;
    __weak KWBackgroundTask *weakSelf = self;
    CFRunLoopTimerRef timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent() + _timeout, 0, 0, 0, ^(CFRunLoopTimerRef timer) {
        [NSException raise:KWBackgroundTaskException format:@"Task %@ timed out", weakSelf];
        CFRunLoopStop(runLoop);
    });
    CFRunLoopAddTimer(runLoop, timer, kCFRunLoopDefaultMode);
    
    id taskObserver = [[NSNotificationCenter defaultCenter] addObserverForName:KWTaskDidTerminateNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        CFRunLoopStop(runLoop);
    }];
    
    [self launch];
    CFRunLoopRun();
    CFRunLoopRemoveTimer(runLoop, timer, kCFRunLoopDefaultMode);
    
    [[NSNotificationCenter defaultCenter] removeObserver:taskObserver];
}

#pragma mark - Private

- (void)launch {
    __block NSTask *task = [[NSTask alloc] init];
    NSMutableDictionary *env = [[NSProcessInfo processInfo].environment mutableCopy];
    env[@"LANG"] = @"en_US.UTF-8";
    [task setEnvironment:env];
    [task setLaunchPath:_command];
    [task setArguments:_arguments];
   
    NSLog(@"Launch: %@ %@", _command, _arguments);
    NSPipe *standardOutput = [NSPipe pipe];
    [task setStandardOutput:standardOutput];
    
    NSPipe *standardError = [NSPipe pipe];
    [task setStandardError:standardError];
    
    _task = task;
    _standardError = standardError;
    _standardOutput = standardOutput;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidTerminate:) name:NSTaskDidTerminateNotification object:task];
    
    @try {
        [_task launch];
    } @catch (NSException *exception) {
        [NSException raise:KWBackgroundTaskException format:@"Task %@ failed to launch", self];
    }
    
    _standardOutputData = [standardOutput.fileHandleForReading readDataToEndOfFile];
    _standardErrorData = [standardError.fileHandleForReading readDataToEndOfFile];
    CFRunLoopRef runLoop = [NSRunLoop currentRunLoop].getCFRunLoop;
    CFRunLoopStop(runLoop);
    [[NSNotificationCenter defaultCenter] postNotificationName:KWTaskDidTerminateNotification object:self];
}

- (void)taskDidTerminate:(NSNotification *)note {
    _terminationStatus = _task.terminationStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:KWTaskDidTerminateNotification object:self];
}

@end
