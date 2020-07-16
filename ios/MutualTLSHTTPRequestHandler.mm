/*
 * This file is based on a copy of:
 * - https://raw.githubusercontent.com/facebook/react-native/0.63-stable/Libraries/Network/RCTHTTPRequestHandler.mm
 *
 * Any changes to the original file are marked with a "PATCH" comment preceding.
 *
 * The original copyright notice for that file appears below, unchanged.
 */

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// PATCH: Changed imports as needed.
#import "MutualTLSHTTPRequestHandler.h"
#import <mutex>
#import <React/RCTHTTPRequestHandler.h>
#import <React/RCTNetworking.h>

// PATCH: Renamed the type and changed the set of protocols implemented.
@interface MutualTLSHTTPRequestHandler () <RCTURLRequestHandler, NSURLSessionDelegate>

@end

@implementation MutualTLSHTTPRequestHandler
{
  NSMapTable *_delegates;
  NSURLSession *_session;
  std::mutex _mutex;
}

@synthesize bridge = _bridge;
@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE()

// PATCH: The subclass needs a higher priority so RCT knows which one to use.
// The default handlerPriority is zero, and if we did not override then this
// handler type would be equal priority to the original and we'd see a warning.
- (float)handlerPriority
{
  // 10 is higher than any standard handler type in react-native,
  // but not absurdly high, so that other libraries could easily override us.
  return 10;
}

- (void)invalidate
{
  std::lock_guard<std::mutex> lock(_mutex);
  [self->_session invalidateAndCancel];
  self->_session = nil;
}

// Needs to lock before call this method.
- (BOOL)isValid
{
  // if session == nil and delegates != nil, we've been invalidated
  return _session || !_delegates;
}

#pragma mark - NSURLRequestHandler

- (BOOL)canHandleRequest:(NSURLRequest *)request
{
  static NSSet<NSString *> *schemes = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // technically, RCTHTTPRequestHandler can handle file:// as well,
    // but it's less efficient than using RCTFileRequestHandler
    schemes = [[NSSet alloc] initWithObjects:@"http", @"https", nil];
  });
  return [schemes containsObject:request.URL.scheme.lowercaseString];
}

- (NSURLSessionDataTask *)sendRequest:(NSURLRequest *)request
                         withDelegate:(id<RCTURLRequestDelegate>)delegate
{
  std::lock_guard<std::mutex> lock(_mutex);
  // Lazy setup
  if (!_session && [self isValid]) {
    // You can override default NSURLSession instance property allowsCellularAccess (default value YES)
    //  by providing the following key to your RN project (edit ios/project/Info.plist file in Xcode):
    // <key>ReactNetworkForceWifiOnly</key>    <true/>
    // This will set allowsCellularAccess to NO and force Wifi only for all network calls on iOS
    // If you do not want to override default behavior, do nothing or set key with value false
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSNumber *useWifiOnly = [infoDictionary objectForKey:@"ReactNetworkForceWifiOnly"];

    NSOperationQueue *callbackQueue = [NSOperationQueue new];
    callbackQueue.maxConcurrentOperationCount = 1;
    callbackQueue.underlyingQueue = [[_bridge networking] methodQueue];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    // Set allowsCellularAccess to NO ONLY if key ReactNetworkForceWifiOnly exists AND its value is YES
    if (useWifiOnly) {
      configuration.allowsCellularAccess = ![useWifiOnly boolValue];
    }
    [configuration setHTTPShouldSetCookies:YES];
    [configuration setHTTPCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    [configuration setHTTPCookieStorage:[NSHTTPCookieStorage sharedHTTPCookieStorage]];
    _session = [NSURLSession sessionWithConfiguration:configuration
                                             delegate:self
                                        delegateQueue:callbackQueue];

    _delegates = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                           valueOptions:NSPointerFunctionsStrongMemory
                                               capacity:0];
  }
  NSURLSessionDataTask *task = [_session dataTaskWithRequest:request];
  [_delegates setObject:delegate forKey:task];
  [task resume];
  return task;
}

- (void)cancelRequest:(NSURLSessionDataTask *)task
{
  {
    std::lock_guard<std::mutex> lock(_mutex);
    [_delegates removeObjectForKey:task];
  }
  [task cancel];
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
  id<RCTURLRequestDelegate> delegate;
  {
    std::lock_guard<std::mutex> lock(_mutex);
    delegate = [_delegates objectForKey:task];
  }
  [delegate URLRequest:task didSendDataWithProgress:totalBytesSent];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
  // Reset the cookies on redirect.
  // This is necessary because we're not letting iOS handle cookies by itself
  NSMutableURLRequest *nextRequest = [request mutableCopy];

  NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
  nextRequest.allHTTPHeaderFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
  completionHandler(nextRequest);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)task
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
  id<RCTURLRequestDelegate> delegate;
  {
    std::lock_guard<std::mutex> lock(_mutex);
    delegate = [_delegates objectForKey:task];
  }
  [delegate URLRequest:task didReceiveResponse:response];
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)task
    didReceiveData:(NSData *)data
{
  id<RCTURLRequestDelegate> delegate;
  {
    std::lock_guard<std::mutex> lock(_mutex);
    delegate = [_delegates objectForKey:task];
  }
  [delegate URLRequest:task didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  id<RCTURLRequestDelegate> delegate;
  {
    std::lock_guard<std::mutex> lock(_mutex);
    delegate = [_delegates objectForKey:task];
    [_delegates removeObjectForKey:task];
  }
  [delegate URLRequest:task didCompleteWithError:error];
}

// PATCH: This delegate handler was added to support authentication challenges.
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
  if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
  {
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* p12DataPath = [mainBundle pathForResource:@"badssl.com-client" ofType:@"p12"];
    NSData *p12Data = [NSData dataWithContentsOfFile:p12DataPath];

    SecIdentityRef identity = nil;
    extractIdentity(p12Data, &identity);

    NSURLCredential* credential = [NSURLCredential credentialWithIdentity:identity certificates:nil persistence:NSURLCredentialPersistenceNone];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
  } else {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
}

// PATCH: This function was added to support loading a client certificate.
OSStatus extractIdentity(NSData *p12Data, SecIdentityRef *identity)
{
  NSString* password = @"badssl.com";
  NSDictionary* options = @{ (id)kSecImportExportPassphrase : password };

  CFArrayRef rawItems = NULL;
  OSStatus status = SecPKCS12Import(
    (__bridge CFDataRef)p12Data,
    (__bridge CFDictionaryRef)options,
    &rawItems
  );

  NSArray* items = (NSArray*)CFBridgingRelease(rawItems); // Transfer to ARC
  NSDictionary* firstItem = nil;
  if ((status == errSecSuccess) && ([items count]>0)) {
    firstItem = items[0];
    *identity =
      (SecIdentityRef)CFBridgingRetain(firstItem[(id)kSecImportItemIdentity]);
  }

  return status;
}

@end

Class MutualTLSHTTPRequestHandlerCls(void) {
  return MutualTLSHTTPRequestHandler.class;
}