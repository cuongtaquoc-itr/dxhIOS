//
//  Trace.m
//  General
//
//  Created by Telit
//  Copyright (c) Telit Wireless Solutions GmbH
//

#import <asl.h>
#import "STTrace.h"


@interface STTrace()

@end

@implementation STTrace
@synthesize callback;

+ (STTrace *)sharedInstance {
    static STTrace *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[STTrace alloc] init];
    });
    return sharedInstance;
}

- (STTrace *)line:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *data = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    return [[STTrace sharedInstance] logData:data withType:@"TIO-LINE"];
}

- (STTrace *)method:(NSString *)format, ... { // Modified implementation
    va_list args;
    va_start(args, format);
    NSString *data = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    return [[STTrace sharedInstance] logData:data withType:@"TIO-METHOD"];
}

- (STTrace *)error:(NSString *)format, ... { // Modified implementation
    va_list args;
    va_start(args, format);
    NSString *data = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    return [[STTrace sharedInstance] logData:data withType:@"TIO-ERROR"];
}

- (STTrace *)logData:(NSString *)data withType:(NSString *)type {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss.SSS"]; // Desired format: dd-mm-yyyy HH:mm:ss.SSS
    NSString *dateTimeString = [formatter stringFromDate:now];
    NSString *logString = [NSString stringWithFormat:@"[%@]-[%@]: %@", dateTimeString, type, data];
    NSLog(@"%@", logString);
    if (self.callback && [self.callback respondsToSelector:@selector(writeFile:)]) {
        NSString *logString = [NSString stringWithFormat:@"[%@] %@", type, data];
        [self.callback writeFile:logString];
    }
    
    return self;
}
// Prevent direct instantiation (optional but recommended)
- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here if needed
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone {
    static STTrace *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}

@end
