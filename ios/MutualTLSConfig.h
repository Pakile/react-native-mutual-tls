#import <foundation/Foundation.h>

@interface MutualTLSConfig : NSObject {
  NSString *keychainServiceForP12;
  NSString *keychainServiceForPassword;
}

@property (nonatomic, retain) NSString *keychainServiceForP12;
@property (nonatomic, retain) NSString *keychainServiceForPassword;

+ (id)global;

@end
