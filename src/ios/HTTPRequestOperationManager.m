//
//  HTTPRequestOperationManager.m
//
//  Created by Aidela Karamyan on 3/24/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "HTTPRequestOperationManager.h"
#import "HTTPRequestOperationData.h"
#import "HTTPRequestOperation.h"

#import "AppDelegate.h"
#import <sqlite3.h>

//#define ENABLE_LOGGING

int const QUEUE_CAPACITY = 1000;
NSString * const DB_FILENAME = @"http_operations.db";


@implementation AppDelegate(BackgroundFetch)

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
#ifdef ENABLE_LOGGING
  NSLog(@"HTTPRequestOperationManager: Performing background fetch");
#endif
  [[HTTPRequestOperationManager sharedInstance] dobakcgroundFetchWithOldestRequest:^(UIBackgroundFetchResult result) {
    completionHandler(result);
  }];
}

@end

#pragma mark -


@interface HTTPRequestOperationManager () <HTTPRequestOperationDelegate>

@property (nonatomic) sqlite3 *database;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *httpRequestQueue;
@property (nonatomic, strong) NSOperationQueue *dbWriteRequestQueue;
@property (nonatomic, strong) NSTimer *networkActivityIndicatorTimer;

@end

@implementation HTTPRequestOperationManager

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static HTTPRequestOperationManager *instance;

  dispatch_once(&onceToken, ^{
    instance = [[[self class] alloc] init];
  });

  return instance;
}

- (instancetype)init {
  self = [super init];

  if (self) {
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPMaximumConnectionsPerHost:1];
    _session = [NSURLSession sessionWithConfiguration:config];

    _httpRequestQueue = [[NSOperationQueue alloc] init];
    [_httpRequestQueue setMaxConcurrentOperationCount:1];

    _dbWriteRequestQueue = [[NSOperationQueue alloc] init];
    [_dbWriteRequestQueue setMaxConcurrentOperationCount:1];

    [self openDatabase];
  }

  return self;
}

- (void)populateQueueWithPendingRequests {
  NSArray *dataArray = [self retrieveAllOperationData];

  for (HTTPRequestOperationData *data in dataArray) {
    HTTPRequestOperation *operation = [[HTTPRequestOperation alloc] initWithOperationData:data];
    [operation setDelegate:self];
    [_httpRequestQueue addOperation:operation];
  }
}

- (void)dobakcgroundFetchWithOldestRequest:(void (^)(UIBackgroundFetchResult result))handler {
  // IMPORTANT: This should be called only from background fetch
  // Reuqest is directly fetched from DB without going through queue

  // Do nothing, if by any chance queue is populated
  if ([_httpRequestQueue operationCount] > 0) {
    handler(UIBackgroundFetchResultNoData);
    return;
  }

  HTTPRequestOperationData *operationData = [self retrieveOldestOperationData];
  if (operationData && operationData.request) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [[_session dataTaskWithRequest:operationData.request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
      NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];

      if (error || ((statusCode / 100) != 2)) {
        handler(UIBackgroundFetchResultFailed);
      } else {
        BOOL success = [self deleteOperationDataWithIdentifier:operationData.identifier];
        handler(success ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultFailed);
      }
    }] resume];
  } else {
    handler(UIBackgroundFetchResultNoData);
  }
}

- (void)addOperationWithRequest:(NSURLRequest *)request completionHandler:(void (^)(BOOL))handler {
  if ([_httpRequestQueue operationCount] >= QUEUE_CAPACITY) {
    handler(NO);
  }

  HTTPRequestOperationData *data = [HTTPRequestOperationData dataWithRequest:request];
  NSBlockOperation *dbOperation = [NSBlockOperation blockOperationWithBlock:^{
    [self insertOperationData:data];

    HTTPRequestOperation *operation = [[HTTPRequestOperation alloc] initWithOperationData:data];
    [operation setDelegate:self];
    [_httpRequestQueue addOperation:operation];

    handler(YES);
  }];

  [dbOperation setQueuePriority:NSOperationQueuePriorityHigh];
  [_dbWriteRequestQueue addOperation:dbOperation];
}

#pragma mark - HTTPRequestOperationDelegate

- (void)finsihedOperationWithIdentifier:(NSString *)identifier {
  NSBlockOperation *dbOperation = [NSBlockOperation blockOperationWithBlock:^{
    [self deleteOperationDataWithIdentifier:identifier];
  }];

  [_dbWriteRequestQueue addOperation:dbOperation];
  [dbOperation waitUntilFinished];
}

#pragma mark - Activity Indicator

- (void)setNetworkActivityIndicatorVisible:(BOOL)visible {
  [_networkActivityIndicatorTimer invalidate];
  _networkActivityIndicatorTimer = nil;

  if (visible) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  } else {
    _networkActivityIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:1.3 repeats:NO block:^(NSTimer * timer) {
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:visible];
    }];
  }
}

#pragma mark - Database

- (void)openDatabase {
  NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *databasePath = [[NSString alloc] initWithString: [dirPaths[0] stringByAppendingPathComponent:DB_FILENAME]];

  if (sqlite3_open([databasePath UTF8String], &_database) == SQLITE_OK) {
    [self createOperationsTable];
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to open database with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }
}

- (void)closeDatabase {
  if (_database) {
    sqlite3_close(_database);
  }
}

- (BOOL)createOperationsTable {
  BOOL success = NO;
  sqlite3_stmt *statement;
  const char *query = "CREATE TABLE Operations( \
                                  id CHAR(50) PRIMARY KEY NOT NULL, \
                                  timestamp CHAR(50), \
                                  request BLOB);";

  if (sqlite3_prepare_v2(_database, query, -1, &statement, nil) == SQLITE_OK) {
    if (sqlite3_step(statement) == SQLITE_DONE) {
      success = YES;
    } else {
#ifdef ENABLE_LOGGING
      NSLog(@"HTTPRequestOperationManager: Failed to create operations table in database with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
    }
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to compile database query with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }

  sqlite3_finalize(statement);
  return success;
}

- (BOOL)insertOperationData:(HTTPRequestOperationData *)operationData {
  BOOL success = NO;
  sqlite3_stmt *statement;
  const char *query = "INSERT INTO Operations(id, timestamp, request) VALUES (?, ?, ?);";

  if (sqlite3_prepare_v2(_database, query, -1, &statement, nil) == SQLITE_OK) {
    sqlite3_bind_text(statement, 1, [operationData.identifier UTF8String], -1, nil);
    sqlite3_bind_text(statement, 2, [operationData.timestamp UTF8String], -1, nil);

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:operationData.request];
    sqlite3_bind_blob64(statement, 3, [data bytes], [data length] , SQLITE_TRANSIENT);

    if (sqlite3_step(statement) == SQLITE_DONE) {
      success = YES;
    } else {
#ifdef ENABLE_LOGGING
      NSLog(@"HTTPRequestOperationManager: Failed to save operation data id-%@ in database with error: %@", [operationData identifier], [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
    }
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to compile database query with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }

  sqlite3_finalize(statement);
  return success;
}

- (HTTPRequestOperationData *)retrieveOperationDataWithIdentifier:(NSString *)identifier {
  HTTPRequestOperationData *result;
  sqlite3_stmt *statement;
  const char *query = "SELECT * FROM Operations WHERE id=?;";

  if (sqlite3_prepare_v2(_database, query, -1, &statement, nil) == SQLITE_OK) {
    sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, nil);

    if (sqlite3_step(statement) == SQLITE_ROW) {
      result = [self parseOperationDataFromStatement:statement];
    }
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to compile database query with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }

  sqlite3_finalize(statement);
  return result;
}

- (HTTPRequestOperationData *)retrieveOldestOperationData {
  HTTPRequestOperationData *result;
  sqlite3_stmt *statement;
  const char *query = "SELECT * FROM Operations ORDER BY date(timestamp) ASC LIMIT 1;";

  if (sqlite3_prepare_v2(_database, query, -1, &statement, nil) == SQLITE_OK) {
    if (sqlite3_step(statement) == SQLITE_ROW) {
      result = [self parseOperationDataFromStatement:statement];
    }
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to compile database query with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }

  sqlite3_finalize(statement);
  return result;
}

- (NSArray<HTTPRequestOperationData *> *)retrieveAllOperationData {
  NSMutableArray *results = [@[] mutableCopy];
  sqlite3_stmt *statement;
  const char *query = "SELECT * FROM Operations;";

  if (sqlite3_prepare_v2(_database, query, -1, &statement, nil) == SQLITE_OK) {
    while (sqlite3_step(statement) == SQLITE_ROW) {
      HTTPRequestOperationData *operationData = [self parseOperationDataFromStatement:statement];
      if (operationData) {
        [results addObject:operationData];
      }
    }
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to compile database query with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }

  sqlite3_finalize(statement);
  return results;
}

- (BOOL)deleteOperationDataWithIdentifier:(NSString *)identifier {
  BOOL result = NO;
  sqlite3_stmt *statement;
  const char *query = "DELETE FROM Operations WHERE id=?;";

  if (sqlite3_prepare_v2(_database, query, -1, &statement, nil) == SQLITE_OK) {
    sqlite3_bind_text(statement, 1, [identifier UTF8String], -1, nil);

    if (sqlite3_step(statement) == SQLITE_DONE) {
      result = YES;
    } else {
#ifdef ENABLE_LOGGING
      NSLog(@"HTTPRequestOperationManager: Failed to delete operation data id-%@ from database with error: %@", identifier, [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
    }
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to compile database query with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }

  sqlite3_finalize(statement);
  return result;
}

- (BOOL)deleteAllOperationData {
  BOOL result = NO;
  sqlite3_stmt *statement;
  const char *query = "DELETE FROM Operations;";

  if (sqlite3_prepare_v2(_database, query, -1, &statement, nil) == SQLITE_OK) {
    if (sqlite3_step(statement) == SQLITE_DONE) {
      result = YES;
    } else {
#ifdef ENABLE_LOGGING
      NSLog(@"HTTPRequestOperationManager: Failed to delete all operation data from database with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
    }
  } else {
#ifdef ENABLE_LOGGING
    NSLog(@"HTTPRequestOperationManager: Failed to compile database query with error: %@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]);
#endif
  }

  sqlite3_finalize(statement);
  return result;
}

- (HTTPRequestOperationData *)parseOperationDataFromStatement:(sqlite3_stmt *)statement {
  HTTPRequestOperationData *result;

  const unsigned char *identifierRaw = sqlite3_column_text(statement, 0);
  NSString *identifier = [NSString stringWithUTF8String:((char *)identifierRaw ?: "")];

  const unsigned char *timestampRaw = sqlite3_column_text(statement, 1);
  NSString *timestamp = [NSString stringWithUTF8String:((char *)timestampRaw ?: "")];

  const void *requestRaw = sqlite3_column_blob(statement, 2);
  int size = sqlite3_column_bytes(statement, 2);

  if (requestRaw) {
    NSData *data = [[NSData alloc] initWithBytes:requestRaw length:size];
    NSURLRequest *request = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    if (request) {
      result = [HTTPRequestOperationData dataWithIdentifier:identifier timestamp:timestamp request:request];
    }
  }

  return result;
}

@end
