//
//  HttpRequester.m
//
//  Created by Aidela Karamyan on 3/22/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "HttpRequester.h"

@interface HttpRequester ()

@property (copy) NSString *callbackId;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end


@implementation HttpRequester

- (void)post:(CDVInvokedUrlCommand *)command {
  _callbackId = command.callbackId;

  _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

  NSDictionary *params = [command.arguments objectAtIndex: 0];
  [self postRequestWithParams:params];
}

- (void)postRequestWithParams:(NSDictionary *)params {
  if (_dataTask) {
    [_dataTask cancel];
  }
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

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

  _dataTask = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    });

    if (error) {
      [self requestFailedWithError:error];
      return;
    }

    NSError *serError;
    NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&serError];

    NSDictionary *result = @{
                             @"statusCode": @([(NSHTTPURLResponse *)response statusCode]),
                             @"data": json ?: @{}
                             };
    [self requestSuccededWithResponse:result];
  }];

  [_dataTask resume];
}

#pragma mark - Callback

- (void)returnWithResult:(CDVPluginResult *)result {
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
  [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
}

- (void)requestSuccededWithResponse:(NSDictionary *)response {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
  [self returnWithResult:result];
}

- (void)requestFailedWithError:(NSError *)error {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
  [self returnWithResult:result];
}

@end
