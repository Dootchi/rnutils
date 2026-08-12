#import <Foundation/Foundation.h>

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

@interface PangleMediationEventEmitter : RCTEventEmitter <RCTBridgeModule>

+ (void)emitEventWithBody:(NSDictionary *)body;

@end

NS_ASSUME_NONNULL_END
