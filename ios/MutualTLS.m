#import "MutualTLS.h"
#import "MutualTLSDebug.h"
#import "MutualTLSConfig.h"

@implementation MutualTLS

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(configure:(NSDictionary *)options
               withResolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject)
{
  [MutualTLSDebug log:@"configuring with" withData:options];
  MutualTLSConfig* config = [MutualTLSConfig global];

  NSString* keychainServiceForP12 = [options objectForKey:@"keychainServiceForP12"];
  if(keychainServiceForP12 && [keychainServiceForP12 isKindOfClass:[NSString class]]) {
    [config setKeychainServiceForP12:keychainServiceForP12];
    [MutualTLSDebug
      log:@"configured setting"
      withData:@{@"keychainServiceForP12":keychainServiceForP12}
    ];
  }

  NSString* keychainServiceForPassword = [options objectForKey:@"keychainServiceForPassword"];
  if(keychainServiceForPassword && [keychainServiceForPassword isKindOfClass:[NSString class]]) {
    [config setKeychainServiceForPassword:keychainServiceForPassword];
    [MutualTLSDebug
      log:@"configured setting"
      withData:@{@"keychainServiceForPassword":keychainServiceForPassword}
    ];
  }

  NSString* insecureDisableVerifyServerInRootDomain = [options objectForKey:@"insecureDisableVerifyServerInRootDomain"];
  if(insecureDisableVerifyServerInRootDomain && [insecureDisableVerifyServerInRootDomain isKindOfClass:[NSString class]]) {
    [config setInsecureDisableVerifyServerInRootDomain:insecureDisableVerifyServerInRootDomain];
    [MutualTLSDebug
      log:@"configured setting"
      withData:@{@"insecureDisableVerifyServerInRootDomain":insecureDisableVerifyServerInRootDomain}
    ];
  }

  resolve(nil);
}

@end
