#import "MutualTLSError.h"

@implementation MutualTLSError

RCT_EXPORT_MODULE()

static MutualTLSError* singleton = nil;

- (void)startObserving {
  singleton = self;
}

- (void)stopObserving {
  singleton = nil;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"MutualTLSError"];
}

+ (void)log:(NSString*)message
   withData:(NSDictionary*)data {
  if (singleton) {
    [singleton
      sendEventWithName:@"MutualTLSError"
      body:@[@"MutualTLS", message, data]
    ];
  }
}

@end
