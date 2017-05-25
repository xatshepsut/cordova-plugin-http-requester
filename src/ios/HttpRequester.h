//
//  HttpRequester.h
//
//  Created by Aidela Karamyan on 3/22/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <Cordova/CDVPlugin.h>

@interface HttpRequester : CDVPlugin

- (void)post:(CDVInvokedUrlCommand *)command;
- (void)put:(CDVInvokedUrlCommand *)command;


@end
