#import "MutualTLSConfig.h"

@implementation MutualTLSConfig

@synthesize keychainServiceForP12;
@synthesize keychainServiceForPassword;

#pragma mark Singleton Methods

+ (MutualTLSConfig*)global {
  static MutualTLSConfig *globalMutualTLSConfig = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    globalMutualTLSConfig = [[self alloc] init];
  });
  return globalMutualTLSConfig;
}

- (id)init {
  if (self = [super init]) {
    keychainServiceForP12 = [[NSString alloc] initWithString:@"mutual-tls.client.p12"];
    keychainServiceForPassword = [[NSString alloc] initWithString:@"mutual-tls.client.p12.password"];
  }
  return self;
}

- (void)dealloc {
  // Never called.
}

@end
