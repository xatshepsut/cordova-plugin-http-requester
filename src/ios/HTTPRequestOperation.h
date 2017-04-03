//
//  HTTPRequestOperation.h
//
//  Created by Aidela Karamyan on 3/24/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTTPRequestOperationData;

@protocol HTTPRequestOperationDelegate <NSObject>

@optional
- (void)startedOperationWithIdentifier:(NSString * _Nonnull)identifier;
- (void)finsihedOperationWithIdentifier:(NSString * _Nonnull)identifier;

@end


@interface HTTPRequestOperation : NSOperation

@property (nonatomic, weak, nullable) id <HTTPRequestOperationDelegate> delegate;
@property (nonatomic, strong, readonly, nonnull) NSString *identifier;

- (instancetype _Nonnull)initWithOperationData:(HTTPRequestOperationData * _Nonnull)data;

@end
