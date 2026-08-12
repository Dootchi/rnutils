#import "PangleMediationEventEmitter.h"

static NSString *const PangleMediationEventName = @"pangleMediation:event";
static PangleMediationEventEmitter *sharedEmitter = nil;

@implementation PangleMediationEventEmitter

RCT_EXPORT_MODULE();

+ (void)emitEventWithBody:(NSDictionary *)body {
  if (sharedEmitter != nil) {
    [sharedEmitter sendEventWithName:PangleMediationEventName body:body];
  }
}

- (instancetype)init {
  if ((self = [super init])) {
    sharedEmitter = self;
  }
  return self;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[ PangleMediationEventName ];
}

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

@end
