//
//  HTTPRequestOperationManager.h
//
//  Created by Aidela Karamyan on 3/24/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTTPRequestOperation;
@class Connectability;

@interface HTTPRequestOperationManager : NSObject

@property (nonatomic, strong, readonly, nullable) NSURLSession *session;

+ (_Nonnull instancetype)sharedInstance;
- (_Nonnull instancetype)init NS_UNAVAILABLE;

- (void)populateQueueWithPendingRequests;
- (void)addOperationWithRequest:(NSURLRequest * _Nonnull)request completionHandler:(void (^ _Nonnull)(BOOL added))handler;
- (void)setNetworkActivityIndicatorVisible:(BOOL)visible;

// IMPORTANT: This should be called only from background fetch
- (void)makeBakcgroundFetchWithOldestRequest:(void (^ _Nonnull)(UIBackgroundFetchResult result))handler;

@end
