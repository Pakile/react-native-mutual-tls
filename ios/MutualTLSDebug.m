#import "MutualTLSDebug.h"

@implementation MutualTLSDebug

RCT_EXPORT_MODULE()

static MutualTLSDebug* singleton = nil;

- (void)startObserving {
  singleton = self;
}

- (void)stopObserving {
  singleton = nil;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"MutualTLSDebug"];
}

+ (void)log:(NSString*)message
   withData:(NSDictionary*)data {
  if (singleton) {
    [singleton
      sendEventWithName:@"MutualTLSDebug"
      body:@[@"MutualTLS", message, data]
    ];
  }
}

@end
