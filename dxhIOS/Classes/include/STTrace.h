//
//  Trace.h
//  General
//
//  Created by Telit
//  Copyright (c) Telit Wireless Solutions GmbH, Germany
//

#import <Foundation/Foundation.h>


@protocol STTraceCallback <NSObject>
- (void)writeFile:(NSString *)data;
@end

@interface STTrace : NSObject

+ (STTrace *)sharedInstance;

- (STTrace *)line:(NSString *)format, ...;
- (STTrace *)method:(NSString *)format, ...; // Modified to accept variable arguments
- (STTrace *)error:(NSString *)format, ...; // Modified to accept variable arguments
- (STTrace *)logData:(NSString *)data withType:(NSString *)type;

@property (nonatomic, weak) id<STTraceCallback> callback;

@end
