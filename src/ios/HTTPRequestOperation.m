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
    _data = data;

#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperation: Initialized operation with id \"%@\"", data.identifier);
#endif
  }

  return self;
}

- (void)retry {
#ifdef ENABLE_LOGGING
  NSLog(@"HTTPRequestOperation: Retrying operation with id \"%@\"", _data.identifier);
#endif
  [self makeRequest];
}

- (NSString *)identifier {
  return _data.identifier;
}

- (NSInteger)retryCounter {
  return _data.retryCounter;
}

- (void)incrementRetryCounter {
  _data.retryCounter++;
}

- (void)makeRequest {
#ifdef ENABLE_LOGGING
  NSLog(@"HTTPRequestOperation: Executing operation with id \"%@\"", _data.identifier);
#endif

  _task = [[[HTTPRequestOperationManager sharedInstance] session] dataTaskWithRequest:_data.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[HTTPRequestOperationManager sharedInstance] setNetworkActivityIndicatorVisible:NO];
    });

    if (error) {
      if ([_delegate respondsToSelector:@selector(failedOperation:withError:)]) {
        [_delegate failedOperation:self withError:error];
      } else {
        [self finish];
      }
      return;
    }

    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    NSJSONSerialization *json;

    if (data) {
      NSError *serError;
      json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&serError];
    }

    NSString *requestStatus = [(NSDictionary *)json objectForKey:@"status"];

#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperation: Operation %@ result code - %ld, status - %@", _data.identifier, (long)statusCode, requestStatus);
#endif

    BOOL failed = (statusCode / 100 != 2) || [[requestStatus lowercaseString] isEqualToString:@"error"];

    if (failed && [_delegate respondsToSelector:@selector(failedOperation:withError:)]) {
      [_delegate failedOperation:self withError:[NSError errorWithDomain:@"HTTPErrorDomain" code:statusCode userInfo:nil]];
    } else {
      [self finish];
    }
  }];

  [_task resume];
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
  NSLog(@"HTTPRequestOperation: Started operation with id \"%@\"", _data.identifier);
#endif

  [self makeRequest];

  dispatch_async(dispatch_get_main_queue(), ^{
    [[HTTPRequestOperationManager sharedInstance] setNetworkActivityIndicatorVisible:YES];
  });

  if ([_delegate respondsToSelector:@selector(startedOperation:)]) {
    [_delegate startedOperation:self];
  }
}

- (void)finish {
  if (!self.isExecuting) {
    return;
  }

  self.executing = NO;
  self.finished = YES;
#ifdef ENABLE_LOGGING
  NSLog(@"HTTPRequestOperation: Finished operation with id \"%@\"", _data.identifier);
#endif

  if ([_delegate respondsToSelector:@selector(finishedOperation:)]) {
    [_delegate finishedOperation:self];
  }
}

- (void)cancel {
  [super cancel];
  [self finish];
}

@end
