//
//  HTTPRequestOperation.m
//
//  Created by Aidela Karamyan on 3/24/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "HTTPRequestOperation.h"
#import "HTTPRequestOperationData.h"
#import "HTTPRequestOperationManager.h"

//#define ENABLE_LOGGING


@interface HTTPRequestOperation ()

@property (nonatomic, strong) HTTPRequestOperationData *data;
@property (nonatomic, strong) NSURLSessionDataTask *task;

@end


@implementation HTTPRequestOperation

@synthesize ready = _ready;
@synthesize executing = _executing;
@synthesize finished = _finished;


- (instancetype)initWithOperationData:(HTTPRequestOperationData *)data {
  self = [super init];

  if (self) {
    self.ready = YES;
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperation: Initialized operation with name \"%@\"", data.identifier);
#endif

    _data = data;
    _task = [[[HTTPRequestOperationManager sharedInstance] session] dataTaskWithRequest:data.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [[HTTPRequestOperationManager sharedInstance] setNetworkActivityIndicatorVisible:NO];
      });

      NSError *serError;
      NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&serError];
#ifdef ENABLE_LOGGING
      NSLog(@"HTTPRequestOperation: Result statusCode - %ld, data - %@", (long)[(NSHTTPURLResponse *)response statusCode], json ?: @{});
#endif

      [self finish];
    }];
  }

  return self;
}

- (NSString *)identifier {
  return _data.identifier;
}

#pragma mark - State

- (void)setReady:(BOOL)ready {
  if (_ready != ready) {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    _ready = ready;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
  }
}

- (BOOL)isReady {
  return _ready;
}

- (void)setExecuting:(BOOL)executing {
  if (_executing != executing) {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _executing = executing;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
  }
}

- (BOOL)isExecuting {
  return _executing;
}

- (void)setFinished:(BOOL)finished {
  if (_finished != finished) {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _finished = finished;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
  }
}

- (BOOL)isFinished {
  return _finished;
}

- (BOOL)isAsynchronous {
  return YES;
}

#pragma mark - Control

- (void)start {
  if (self.isExecuting) {
    return;
  }

  self.ready = NO;
  self.executing = YES;
  self.finished = NO;
#ifdef ENABLE_LOGGING
  NSLog(@"HTTPRequestOperation: Started operation with name \"%@\"", _data.identifier);
#endif

  [_task resume];

  dispatch_async(dispatch_get_main_queue(), ^{
    [[HTTPRequestOperationManager sharedInstance] setNetworkActivityIndicatorVisible:YES];
  });

  if ([_delegate respondsToSelector:@selector(startedOperationWithIdentifier:)]) {
    [_delegate startedOperationWithIdentifier:_data.identifier];
  }
}

- (void)finish {
  if (!self.isExecuting) {
    return;
  }

  self.executing = NO;
  self.finished = YES;
#ifdef ENABLE_LOGGING
  NSLog(@"HTTPRequestOperation: Finished operation with name \"%@\"", _data.identifier);
#endif

  if ([_delegate respondsToSelector:@selector(finsihedOperationWithIdentifier:)]) {
    [_delegate finsihedOperationWithIdentifier:_data.identifier];
  }
}

- (void)cancel {
  [super cancel];
  [self finish];
}

@end
