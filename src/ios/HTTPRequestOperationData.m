//
//  HTTPRequestOperationData.m
//
//  Created by Aidela Karamyan on 3/27/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "HTTPRequestOperationData.h"

@implementation HTTPRequestOperationData

+ (instancetype)dataWithRequest:(NSURLRequest *)request {
  HTTPRequestOperationData *data = [[HTTPRequestOperationData alloc] init];

  if (data) {
    data.identifier = [self uuid];
    data.timestamp = [self timestamp:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    data.request = request;
    data.retryCounter = 0;
  }

  return data;
}

+ (instancetype)dataWithIdentifier:(NSString *)identifier timestamp:(NSString *)timestamp request:(NSURLRequest *)request retryCounter:(NSInteger)counter {
  HTTPRequestOperationData *data = [[HTTPRequestOperationData alloc] init];

  if (data) {
    data.identifier = identifier;
    data.timestamp = timestamp;
    data.request = request;
    data.retryCounter = counter;
  }

  return data;
}

+ (NSString *)timestamp:(NSString *)format {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
  [dateFormatter setDateFormat:format];
  return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSString *)uuid {
  CFUUIDRef uuidRef = CFUUIDCreate(NULL);
  CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
  CFRelease(uuidRef);
  return (__bridge_transfer NSString *)uuidStringRef;
}

@end
