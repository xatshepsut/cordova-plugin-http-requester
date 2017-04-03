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
    data.timestamp = [self timestamp];
    data.request = request;
  }

  return data;
}

+ (instancetype)dataWithIdentifier:(NSString *)identifier timestamp:(NSString *)timestamp request:(NSURLRequest *)request {
  HTTPRequestOperationData *data = [[HTTPRequestOperationData alloc] init];

  if (data) {
    data.identifier = identifier;
    data.timestamp = timestamp;
    data.request = request;
  }

  return data;
}

+ (NSString *)timestamp {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
  return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSString *)uuid {
  CFUUIDRef uuidRef = CFUUIDCreate(NULL);
  CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
  CFRelease(uuidRef);
  return (__bridge_transfer NSString *)uuidStringRef;
}

@end
