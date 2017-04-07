//
//  HTTPRequestOperation.h
//
//  Created by Aidela Karamyan on 3/24/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTTPRequestOperationData;
@class HTTPRequestOperation;

@protocol HTTPRequestOperationDelegate <NSObject>
@optional
- (void)startedOperation:(HTTPRequestOperation * _Nonnull)operation;
- (void)finishedOperation:(HTTPRequestOperation * _Nonnull)operation;
- (void)failedOperation:(HTTPRequestOperation * _Nonnull)operation withError:(NSError * _Nullable)error;

@end


@interface HTTPRequestOperation : NSOperation

@property (nonatomic, weak, nullable) id <HTTPRequestOperationDelegate> delegate;
@property (nonatomic, strong, readonly, nonnull) NSString *identifier;
@property (nonatomic, assign, readonly) NSInteger retryCounter;

- (instancetype _Nonnull)initWithOperationData:(HTTPRequestOperationData * _Nonnull)data;
- (void)incrementRetryCounter;
- (void)retry;

@end
