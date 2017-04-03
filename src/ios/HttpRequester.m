//
//  HttpRequester.m
//
//  Created by Aidela Karamyan on 3/22/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "HttpRequester.h"
#import "HTTPRequestOperationManager.h"

@interface HttpRequester ()

@property (copy) NSString *callbackId;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end


@implementation HttpRequester

- (void)pluginInitialize {
  [[HTTPRequestOperationManager sharedInstance] populateQueueWithPendingRequests];
}

- (void)post:(CDVInvokedUrlCommand *)command {
  _callbackId = command.callbackId;
  NSDictionary *params = [command.arguments objectAtIndex: 0];

  dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSURLRequest *request = [self postRequestWithParams:params];
    [[HTTPRequestOperationManager sharedInstance] addOperationWithRequest:request completionHandler:^(BOOL added) {
      dispatch_async( dispatch_get_main_queue(), ^{
        if (added) {
          CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Request is succesfully accepted."];
          [self returnWithResult:result];
        } else {
          CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Max number of requests in queue is exceeded."];
          [self returnWithResult:result];
        }
      });
    }];
  });
}

- (NSURLRequest *)postRequestWithParams:(NSDictionary *)params {
  NSString *urlString = [params objectForKey:@"url"];
  NSURL *url = [NSURL URLWithString:urlString];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  NSDictionary *body = [params objectForKey:@"body"];
  NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
  [request setHTTPBody:data];

  NSString *dataLength = [NSString stringWithFormat:@"%lu", (unsigned long)[data length]];
  [request setValue:dataLength forHTTPHeaderField:@"Content-Length"];


  NSString *authorization = [params objectForKey:@"authorization"];
  if (authorization) {
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
  }

  return request;
}

- (void)returnWithResult:(CDVPluginResult *)result {
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
  [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
}


@end
