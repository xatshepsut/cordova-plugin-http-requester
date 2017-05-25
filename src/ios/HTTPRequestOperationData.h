//
//  HTTPRequestOperationData.h
//
//  Created by Aidela Karamyan on 3/27/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPRequestOperationData : NSObject

@property (nonatomic, strong, nonnull) NSString *identifier;
@property (nonatomic, strong, nonnull) NSString *timestamp;
@property (nonatomic, strong, nonnull) NSURLRequest *request;
@property (nonatomic, assign) NSInteger retryCounter;

+ (instancetype _Nonnull)dataWithRequest:(NSURLRequest * _Nonnull)request;
+ (instancetype _Nonnull)dataWithIdentifier:(NSString * _Nonnull)identifier timestamp:(NSString * _Nonnull)timestamp request:(NSURLRequest * _Nonnull)request retryCounter:(NSInteger)counter;

+ (NSString *)timestamp:(NSString *)format;
+ (NSString *)uuid;

@end
