#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface MutualTLSError : RCTEventEmitter <RCTBridgeModule>

+ (void)log:(NSString*)message
   withData:(NSDictionary*)data;

@end
