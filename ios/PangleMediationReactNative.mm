#import "PangleMediationReactNative.h"

#import <PAGAdSDK/PAGAdSDK.h>
#import <PAGAdSDK/PAGConfig+PAGMediationSetting.h>
#import <PAGAdSDK/PAGSdk+PAGMediation.h>
#import <PAGAdSDK/PAGUserInfoForSegment.h>
#import <PAGAdSDK/PAGLInterstitialAd+PAGMediation.h>
#import <PAGAdSDK/PAGRewardedAd+PAGMediation.h>
#import <PAGAdSDK/PAGRequest+PAGMediation.h>
#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <objc/runtime.h>

#import "PangleMediationEventEmitter.h"

static char kPangleAdTypeAssociationKey;
static char kPangleAdUnitIdAssociationKey;
static char kPangleInstanceIdAssociationKey;
static NSInteger const PangleMediationErrorInvalidAdInstance = -1;
static NSInteger const PangleMediationErrorAdNotFound = -3;
static NSInteger const PangleMediationErrorPresentationControllerUnavailable = -4;

@interface PangleMediationReactNative () <PAGLInterstitialAdDelegate, PAGRewardedAdDelegate>
@property(nonatomic, strong) NSMutableDictionary<NSString *, PAGLInterstitialAd *> *interstitialAds;
@property(nonatomic, strong) NSMutableDictionary<NSString *, PAGRewardedAd *> *rewardedAds;
@end

@implementation PangleMediationReactNative

RCT_EXPORT_MODULE();

- (instancetype)init {
  if ((self = [super init])) {
    _interstitialAds = [NSMutableDictionary new];
    _rewardedAds = [NSMutableDictionary new];
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

RCT_REMAP_METHOD(initialize,
                 initializeWithOptions:(NSDictionary *)options
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  NSString *appId = [RCTConvert NSString:options[@"appId"]];
  if (appId.length == 0) {
    reject(@"invalid_init_options", @"initialize() requires a non-empty appId", nil);
    return;
  }

  PAGConfig *config = [PAGConfig shareConfig];
  config.appID = appId;
#if DEBUG
  config.debugLog = [RCTConvert BOOL:options[@"debugLogEnabled"]];
#endif

  NSString *userData = [RCTConvert NSString:options[@"userData"]];
  if (userData.length > 0) {
    config.userDataString = userData;
  }

  NSDictionary *segment = [RCTConvert NSDictionary:options[@"segment"]];
  if (segment != nil) {
    RCTLogInfo(@"[PangleMediation] initialize received segment: %@",
               [self segmentSummaryFromDictionary:segment]);
    PAGUserInfoForSegment *segmentInfo = [self segmentInfoFromDictionary:segment];
    if (segmentInfo != nil) {
      [config setUserInfoForSegment:segmentInfo];
      RCTLogInfo(@"[PangleMediation] initialize applied segment successfully");
    } else {
      RCTLogWarn(@"[PangleMediation] initialize ignored segment because no valid fields were found");
    }
  }

  if (options[@"setDisableInitAdn"] != nil && options[@"setDisableInitAdn"] != (id)kCFNull) {
    NSArray<PAGMADNName> *disableInitAdns = [self stringArrayFromValue:options[@"setDisableInitAdn"]];
    config.disableInitAdns = disableInitAdns;
    RCTLogInfo(@"[PangleMediation] disable init ands:%@",disableInitAdns);
  }

  NSDictionary *privacySettings = [RCTConvert NSDictionary:options[@"privacySettings"]];
  if (privacySettings != nil) {
    [self applyPrivacySettings:privacySettings];
  }

  [PAGSdk startWithMediationConfig:config
                 completionHandler:^(NSDictionary *_Nullable info, NSError *_Nullable error) {
                   if (error != nil) {
                     reject([NSString stringWithFormat:@"%ld", (long)error.code],
                            error.localizedDescription,
                            error);
                     return;
                   }

                   resolve(@{
                     @"success" : @YES,
                     @"code" : @"0",
                     @"message" : @"Pangle mediation initialized successfully",
                   });
                 }];
}

RCT_REMAP_METHOD(getSdkVersion,
                 getSdkVersionWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  resolve(PAGSdk.SDKVersion ?: [NSNull null]);
}

RCT_REMAP_METHOD(updateSegment,
                 updateSegment:(NSDictionary *)segment
                 segmentResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  RCTLogInfo(@"[PangleMediation] updateSegment called with payload: %@",
             [self segmentSummaryFromDictionary:segment]);
  PAGUserInfoForSegment *segmentInfo = [self segmentInfoFromDictionary:segment];
  if (segmentInfo == nil) {
    RCTLogWarn(@"[PangleMediation] updateSegment rejected because no valid segment fields were found");
    reject(@"invalid_segment", @"updateSegment() requires at least one valid segment field", nil);
    return;
  }

  [[PAGConfig shareConfig] setUserInfoForSegment:segmentInfo];
  RCTLogInfo(@"[PangleMediation] updateSegment applied successfully");
  resolve(nil);
}

RCT_REMAP_METHOD(updatePrivacySettings,
                 updatePrivacySettings:(NSDictionary *)settings
                 privacyResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  [self applyPrivacySettings:settings];
  resolve(nil);
}

RCT_REMAP_METHOD(openTestSuite,
                 openTestSuiteWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_main_queue(), ^{
    Class visualDebugClass = NSClassFromString(@"PAGMVisualDebug");
    SEL startVisualDebugSelector = NSSelectorFromString(@"startVisualDebug");
    if (visualDebugClass != Nil &&
        [visualDebugClass respondsToSelector:startVisualDebugSelector]) {
      ((void (*)(id, SEL))[visualDebugClass methodForSelector:startVisualDebugSelector])(
          visualDebugClass, startVisualDebugSelector);
      resolve(nil);
      return;
    }

    reject(@"test_suite_unavailable",
           @"PAGMVisualDebug is unavailable. Make sure the MTestSuite dependency is linked.",
           nil);
  });
}

RCT_REMAP_METHOD(loadInterstitial,
                 loadInterstitialWithAdUnitId:(NSString *)adUnitId
                 instanceId:(NSString *)instanceId
                 options:(NSDictionary *)options) {
  if (instanceId.length == 0) {
    [self emitEvent:@"interstitial"
            adUnitId:adUnitId
           instanceId:instanceId
                 type:@"load_failed"
            errorCode:@(PangleMediationErrorInvalidAdInstance)
         errorMessage:@"loadInterstitial() requires a non-empty instanceId"
               reward:nil
                 ecpm:nil];
    return;
  }

  PAGInterstitialRequest *request = [PAGInterstitialRequest request];
  [self applyMuteFromOptions:options toRequest:request];
  __weak __typeof__(self) weakSelf = self;
  [PAGLInterstitialAd loadAdWithSlotID:adUnitId
                               request:request
                     completionHandler:^(PAGLInterstitialAd *_Nullable interstitialAd, NSError *_Nullable error) {
                       __strong __typeof__(weakSelf) self = weakSelf;
                       if (self == nil) {
                         return;
                       }

                       if (error != nil) {
                         [self emitEvent:@"interstitial"
                                 adUnitId:adUnitId
                                instanceId:instanceId
                                      type:@"load_failed"
                                     error:error
                                    reward:nil
                                      ecpm:nil];
                         return;
                       }

                       self.interstitialAds[instanceId] = interstitialAd;
                       [self attachMetadataForAd:interstitialAd
                                         adType:@"interstitial"
                                      adUnitId:adUnitId
                                     instanceId:instanceId];
                       interstitialAd.delegate = self;
                       [self emitEvent:@"interstitial"
                               adUnitId:adUnitId
                              instanceId:instanceId
                                    type:@"loaded"
                                  error:nil
                                 reward:nil
                                    ecpm:[self ecpmDictionaryForWinAd:interstitialAd]];
                     }];
}

RCT_REMAP_METHOD(showInterstitial,
                 showInterstitialWithInstanceId:(NSString *)instanceId) {
  if (instanceId.length == 0) {
    [self emitEvent:@"interstitial"
            adUnitId:@""
           instanceId:instanceId
                 type:@"show_failed"
            errorCode:@(PangleMediationErrorInvalidAdInstance)
         errorMessage:@"showInterstitial() requires a non-empty instanceId"
               reward:nil
                 ecpm:nil];
    return;
  }

  PAGLInterstitialAd *ad = self.interstitialAds[instanceId];
  if (ad == nil) {
    [self emitEvent:@"interstitial"
            adUnitId:@""
           instanceId:instanceId
                 type:@"show_failed"
            errorCode:@(PangleMediationErrorAdNotFound)
         errorMessage:@"No cached interstitial ad for the given instance"
               reward:nil
                 ecpm:nil];
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *viewController = [self currentVisibleViewController];
    if (viewController == nil) {
      [self emitEvent:@"interstitial"
              adUnitId:[self adUnitIdForAd:ad] ?: @""
             instanceId:instanceId
                   type:@"show_failed"
              errorCode:@(PangleMediationErrorPresentationControllerUnavailable)
           errorMessage:@"Unable to find a visible iOS view controller to present the interstitial ad"
                 reward:nil
                   ecpm:nil];
      [self removeStoredAdForType:@"interstitial" instanceId:instanceId];
      return;
    }

    @try {
      [ad presentFromRootViewController:viewController];
    } @catch (NSException *exception) {
      [self emitEvent:@"interstitial"
              adUnitId:[self adUnitIdForAd:ad] ?: @""
             instanceId:instanceId
                   type:@"show_failed"
              errorCode:@(PangleMediationErrorPresentationControllerUnavailable)
           errorMessage:exception.reason ?: @"Failed to present interstitial ad"
                 reward:nil
                   ecpm:nil];
      [self removeStoredAdForType:@"interstitial" instanceId:instanceId];
    }
  });
}

RCT_REMAP_METHOD(loadRewarded,
                 loadRewardedWithAdUnitId:(NSString *)adUnitId
                 instanceId:(NSString *)instanceId
                 options:(NSDictionary *)options) {
  if (instanceId.length == 0) {
    [self emitEvent:@"rewarded"
            adUnitId:adUnitId
           instanceId:instanceId
                 type:@"load_failed"
            errorCode:@(PangleMediationErrorInvalidAdInstance)
         errorMessage:@"loadRewarded() requires a non-empty instanceId"
               reward:nil
                 ecpm:nil];
    return;
  }

  PAGRewardedRequest *request = [PAGRewardedRequest request];
  [self applyMuteFromOptions:options toRequest:request];
  __weak __typeof__(self) weakSelf = self;
  [PAGRewardedAd loadAdWithSlotID:adUnitId
                          request:request
                completionHandler:^(PAGRewardedAd *_Nullable rewardedAd, NSError *_Nullable error) {
                  __strong __typeof__(weakSelf) self = weakSelf;
                  if (self == nil) {
                    return;
                  }

                  if (error != nil) {
                    [self emitEvent:@"rewarded"
                            adUnitId:adUnitId
                           instanceId:instanceId
                                 type:@"load_failed"
                               error:error
                              reward:nil
                                 ecpm:nil];
                    return;
                  }

                  self.rewardedAds[instanceId] = rewardedAd;
                  [self attachMetadataForAd:rewardedAd
                                    adType:@"rewarded"
                                 adUnitId:adUnitId
                                instanceId:instanceId];
                  rewardedAd.delegate = self;
                  [self emitEvent:@"rewarded"
                          adUnitId:adUnitId
                         instanceId:instanceId
                              type:@"loaded"
                             error:nil
                            reward:nil
                              ecpm:[self ecpmDictionaryForWinAd:rewardedAd]];
                }];
}

RCT_REMAP_METHOD(showRewarded,
                 showRewardedWithInstanceId:(NSString *)instanceId) {
  if (instanceId.length == 0) {
    [self emitEvent:@"rewarded"
            adUnitId:@""
           instanceId:instanceId
                 type:@"show_failed"
            errorCode:@(PangleMediationErrorInvalidAdInstance)
         errorMessage:@"showRewarded() requires a non-empty instanceId"
               reward:nil
                 ecpm:nil];
    return;
  }

  PAGRewardedAd *ad = self.rewardedAds[instanceId];
  if (ad == nil) {
    [self emitEvent:@"rewarded"
            adUnitId:@""
           instanceId:instanceId
                 type:@"show_failed"
            errorCode:@(PangleMediationErrorAdNotFound)
         errorMessage:@"No cached rewarded ad for the given instance"
               reward:nil
                 ecpm:nil];
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *viewController = [self currentVisibleViewController];
    if (viewController == nil) {
      [self emitEvent:@"rewarded"
              adUnitId:[self adUnitIdForAd:ad] ?: @""
             instanceId:instanceId
                   type:@"show_failed"
              errorCode:@(PangleMediationErrorPresentationControllerUnavailable)
           errorMessage:@"Unable to find a visible iOS view controller to present the rewarded ad"
                 reward:nil
                   ecpm:nil];
      [self removeStoredAdForType:@"rewarded" instanceId:instanceId];
      return;
    }

    @try {
      [ad presentFromRootViewController:viewController];
    } @catch (NSException *exception) {
      [self emitEvent:@"rewarded"
              adUnitId:[self adUnitIdForAd:ad] ?: @""
             instanceId:instanceId
                   type:@"show_failed"
              errorCode:@(PangleMediationErrorPresentationControllerUnavailable)
           errorMessage:exception.reason ?: @"Failed to present rewarded ad"
                 reward:nil
                   ecpm:nil];
      [self removeStoredAdForType:@"rewarded" instanceId:instanceId];
    }
  });
}

- (UIViewController *_Nullable)currentVisibleViewController {
  UIViewController *presentedViewController = RCTPresentedViewController();
  if ([self isPresentableViewController:presentedViewController]) {
    return presentedViewController;
  }

  UIWindow *window = [self activePresentationWindow];
  return [self visibleViewControllerFromViewController:window.rootViewController];
}

- (UIWindow *_Nullable)activePresentationWindow {
  if (@available(iOS 13.0, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (scene.activationState != UISceneActivationStateForegroundActive ||
          ![scene isKindOfClass:[UIWindowScene class]]) {
        continue;
      }

      UIWindowScene *windowScene = (UIWindowScene *)scene;
      for (UIWindow *window in windowScene.windows) {
        if (window.isKeyWindow) {
          return window;
        }
      }

      for (UIWindow *window in windowScene.windows) {
        if (!window.hidden && window.alpha > 0.0 && window.windowLevel == UIWindowLevelNormal) {
          return window;
        }
      }
    }
  }

  UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
  if (keyWindow != nil) {
    return keyWindow;
  }

  for (UIWindow *window in UIApplication.sharedApplication.windows) {
    if (!window.hidden && window.alpha > 0.0 && window.windowLevel == UIWindowLevelNormal) {
      return window;
    }
  }

  return nil;
}

- (UIViewController *_Nullable)visibleViewControllerFromViewController:(UIViewController *_Nullable)viewController {
  if (viewController == nil) {
    return nil;
  }

  UIViewController *presentedViewController = viewController.presentedViewController;
  if (presentedViewController != nil && !presentedViewController.isBeingDismissed) {
    return [self visibleViewControllerFromViewController:presentedViewController];
  }

  if ([viewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navigationController = (UINavigationController *)viewController;
    return [self visibleViewControllerFromViewController:navigationController.visibleViewController ?: navigationController.topViewController];
  }

  if ([viewController isKindOfClass:[UITabBarController class]]) {
    UITabBarController *tabBarController = (UITabBarController *)viewController;
    return [self visibleViewControllerFromViewController:tabBarController.selectedViewController];
  }

  if ([viewController isKindOfClass:[UISplitViewController class]]) {
    UISplitViewController *splitViewController = (UISplitViewController *)viewController;
    return [self visibleViewControllerFromViewController:splitViewController.viewControllers.lastObject];
  }

  return [self isPresentableViewController:viewController] ? viewController : nil;
}

- (BOOL)isPresentableViewController:(UIViewController *_Nullable)viewController {
  return viewController != nil && viewController.isViewLoaded && viewController.view.window != nil;
}

#pragma mark - PAGAdDelegate

- (void)adDidShow:(id<PAGAdProtocol>)ad {
  [self emitLifecycleEventType:@"shown" forAd:ad error:nil];
}

- (void)adDidClick:(id<PAGAdProtocol>)ad {
  [self emitLifecycleEventType:@"clicked" forAd:ad error:nil];
}

- (void)adDidDismiss:(id<PAGAdProtocol>)ad {
  [self emitLifecycleEventType:@"dismissed" forAd:ad error:nil];
}

- (void)adDidShowFail:(id<PAGAdProtocol>)ad error:(NSError *)error {
  [self emitLifecycleEventType:@"show_failed" forAd:ad error:error];
}

- (void)adDidReturnRevenue:(id<PAGAdProtocol>)ad info:(PAGAdEcpmInfo *)revenueInfo {
  NSString *adType = [self adTypeForAd:ad] ?: @"";
  NSString *adUnitId = [self adUnitIdForAd:ad] ?: @"";
  NSString *instanceId = [self instanceIdForAd:ad];

  [self emitEvent:adType
          adUnitId:adUnitId
         instanceId:instanceId
               type:@"revenue"
              error:nil
             reward:nil
               ecpm:[self ecpmDictionaryFromInfo:revenueInfo]];
}

#pragma mark - PAGRewardedAdDelegate

- (void)rewardedAd:(PAGRewardedAd *)rewardedAd userDidEarnReward:(PAGRewardModel *)rewardModel {
  [self emitEvent:@"rewarded"
          adUnitId:[self adUnitIdForAd:rewardedAd] ?: @""
         instanceId:[self instanceIdForAd:rewardedAd]
               type:@"reward_earned"
              error:nil
             reward:@{
               @"name" : rewardModel.rewardName ?: @"",
               @"amount" : @(rewardModel.rewardAmount),
             }
               ecpm:nil];
}

- (void)rewardedAd:(PAGRewardedAd *)rewardedAd userEarnRewardFailWithError:(NSError *)error {
  [self emitEvent:@"rewarded"
          adUnitId:[self adUnitIdForAd:rewardedAd] ?: @""
         instanceId:[self instanceIdForAd:rewardedAd]
               type:@"reward_failed"
              error:error
             reward:nil
               ecpm:nil];
}

#pragma mark - helpers

- (void)applyMuteFromOptions:(NSDictionary *)options toRequest:(PAGRequest *)request {
  if (![options isKindOfClass:[NSDictionary class]]) {
    return;
  }
  id mute = options[@"mute"];
  if (mute == nil || mute == (id)kCFNull) {
    return;
  }
  BOOL muteValue = [RCTConvert BOOL:mute];
  [request setMute:muteValue];
  RCTLogInfo(@"[PangleMediation] request set mute:%@",@(muteValue));
}

- (NSArray<NSString *> *)stringArrayFromValue:(id)value {
  NSArray *rawValues = [RCTConvert NSArray:value];
  NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:rawValues.count];
  for (id item in rawValues) {
    NSString *stringValue = [RCTConvert NSString:item];
    if (stringValue.length > 0) {
      [values addObject:stringValue];
    }
  }
  return values;
}

- (PAGUserInfoForSegment *_Nullable)segmentInfoFromDictionary:(NSDictionary *)segment {
  if (segment == nil || ![segment isKindOfClass:[NSDictionary class]]) {
    RCTLogWarn(@"[PangleMediation] segment payload is not a valid dictionary");
    return nil;
  }

  PAGUserInfoForSegment *userInfo = [PAGUserInfoForSegment new];
  BOOL hasValue = NO;

  NSString *userId = [RCTConvert NSString:segment[@"userId"]];
  if (userId.length > 0) {
    userInfo.user_id = userId;
    hasValue = YES;
  }

  NSString *channel = [RCTConvert NSString:segment[@"channel"]];
  if (channel.length > 0) {
    userInfo.channel = channel;
    hasValue = YES;
  }

  NSString *subChannel = [RCTConvert NSString:segment[@"subChannel"]];
  if (subChannel.length > 0) {
    userInfo.sub_channel = subChannel;
    hasValue = YES;
  }

  NSNumber *age = [RCTConvert NSNumber:segment[@"age"]];
  if (age != nil) {
    userInfo.age = age.integerValue;
    hasValue = YES;
  }

  NSString *gender = [RCTConvert NSString:segment[@"gender"]];
  if (gender.length > 0) {
    userInfo.gender = [self segmentGenderFromString:gender];
    hasValue = YES;
  }

  NSString *userValueGroup = [RCTConvert NSString:segment[@"userValueGroup"]];
  if (userValueGroup.length > 0) {
    userInfo.user_value_group = userValueGroup;
    hasValue = YES;
  }

  NSDictionary *customInfos = [RCTConvert NSDictionary:segment[@"customInfos"]];
  if (customInfos.count > 0) {
    NSMutableDictionary<NSString *, NSString *> *normalized = [NSMutableDictionary dictionaryWithCapacity:customInfos.count];
    [customInfos enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      NSString *normalizedKey = [RCTConvert NSString:key];
      NSString *normalizedValue = [RCTConvert NSString:obj];
      if (normalizedKey.length > 0 && normalizedValue.length > 0) {
        normalized[normalizedKey] = normalizedValue;
      }
    }];
    if (normalized.count > 0) {
      userInfo.customized_id = normalized;
      hasValue = YES;
    } else {
      RCTLogWarn(@"[PangleMediation] segment.customInfos was provided but no valid string pairs were kept");
    }
  }

  if (!hasValue) {
    RCTLogWarn(@"[PangleMediation] segment payload did not contain any usable fields");
  }

  return hasValue ? userInfo : nil;
}

- (PAGUserInfoGender)segmentGenderFromString:(NSString *)gender {
  if ([gender isEqualToString:@"female"]) {
    return PAGUserInfoGenderFemale;
  }
  if ([gender isEqualToString:@"male"]) {
    return PAGUserInfoGenderMale;
  }
  if (![gender isEqualToString:@"unknown"] && gender.length > 0) {
    RCTLogWarn(@"[PangleMediation] unsupported segment.gender '%@', fallback to unknown", gender);
  }
  return PAGUserInfoGenderUnknown;
}

- (NSString *)segmentSummaryFromDictionary:(NSDictionary *)segment {
  if (segment == nil || ![segment isKindOfClass:[NSDictionary class]]) {
    return @"<invalid>";
  }

  NSMutableArray<NSString *> *fields = [NSMutableArray array];
  if ([RCTConvert NSString:segment[@"userId"]].length > 0) {
    [fields addObject:@"userId"];
  }
  if ([RCTConvert NSString:segment[@"channel"]].length > 0) {
    [fields addObject:@"channel"];
  }
  if ([RCTConvert NSString:segment[@"subChannel"]].length > 0) {
    [fields addObject:@"subChannel"];
  }
  if ([RCTConvert NSNumber:segment[@"age"]] != nil) {
    [fields addObject:@"age"];
  }
  if ([RCTConvert NSString:segment[@"gender"]].length > 0) {
    [fields addObject:@"gender"];
  }
  if ([RCTConvert NSString:segment[@"userValueGroup"]].length > 0) {
    [fields addObject:@"userValueGroup"];
  }

  NSDictionary *customInfos = [RCTConvert NSDictionary:segment[@"customInfos"]];
  if (customInfos.count > 0) {
    [fields addObject:[NSString stringWithFormat:@"customInfos(%lu)", (unsigned long)customInfos.count]];
  }

  if (fields.count == 0) {
    return @"<empty>";
  }
  return [fields componentsJoinedByString:@","];
}

- (void)applyPrivacySettings:(NSDictionary *)settings {
  NSString *childDirected = [RCTConvert NSString:settings[@"childDirected"]];
  if ([childDirected isEqualToString:@"child"]) {
    [PAGConfig shareConfig].childDirected = PAGChildDirectedTypeChild;
  } else if ([childDirected isEqualToString:@"nonChild"]) {
    [PAGConfig shareConfig].childDirected = PAGChildDirectedTypeNonChild;
  } else {
    [PAGConfig shareConfig].childDirected = PAGChildDirectedTypeDefault;
  }

  NSString *gdprConsent = [RCTConvert NSString:settings[@"gdprConsent"]];
  if ([gdprConsent isEqualToString:@"noConsent"]) {
    [PAGConfig shareConfig].GDPRConsent = PAGGDPRConsentTypeNoConsent;
  } else if ([gdprConsent isEqualToString:@"consent"]) {
    [PAGConfig shareConfig].GDPRConsent = PAGGDPRConsentTypeConsent;
  } else {
    [PAGConfig shareConfig].GDPRConsent = PAGGDPRConsentTypeDefault;
  }

  NSString *doNotSell = [RCTConvert NSString:settings[@"doNotSell"]];
  if ([doNotSell isEqualToString:@"sell"]) {
    [PAGConfig shareConfig].doNotSell = PAGDoNotSellTypeSell;
  } else if ([doNotSell isEqualToString:@"notSell"]) {
    [PAGConfig shareConfig].doNotSell = PAGDoNotSellTypeNotSell;
  } else {
    [PAGConfig shareConfig].doNotSell = PAGDoNotSellTypeDefault;
  }

  NSString *paConsent = [RCTConvert NSString:settings[@"paConsent"]];
  if ([paConsent isEqualToString:@"consent"]) {
    [PAGConfig shareConfig].PAConsent = PAGPAConsentTypeConsent;
  }
  else if ([paConsent isEqualToString:@"noConsent"]) {
    [PAGConfig shareConfig].PAConsent = PAGPAConsentTypeNoConsent;
  }
  
  RCTLogInfo(@"[PangleMediation] apply privacy settings:%@",settings);
}

- (void)attachMetadataForAd:(id)ad
                     adType:(NSString *)adType
                   adUnitId:(NSString *)adUnitId
                 instanceId:(NSString *)instanceId {
  objc_setAssociatedObject(ad, &kPangleAdTypeAssociationKey, adType, OBJC_ASSOCIATION_COPY_NONATOMIC);
  objc_setAssociatedObject(ad, &kPangleAdUnitIdAssociationKey, adUnitId, OBJC_ASSOCIATION_COPY_NONATOMIC);
  objc_setAssociatedObject(ad, &kPangleInstanceIdAssociationKey, instanceId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *_Nullable)adTypeForAd:(id)ad {
  return objc_getAssociatedObject(ad, &kPangleAdTypeAssociationKey);
}

- (NSString *_Nullable)adUnitIdForAd:(id)ad {
  return objc_getAssociatedObject(ad, &kPangleAdUnitIdAssociationKey);
}

- (NSString *_Nullable)instanceIdForAd:(id)ad {
  return objc_getAssociatedObject(ad, &kPangleInstanceIdAssociationKey);
}

- (void)removeStoredAdForType:(NSString *_Nullable)adType instanceId:(NSString *_Nullable)instanceId {
  if (instanceId.length == 0) {
    return;
  }

  if ([adType isEqualToString:@"interstitial"]) {
    [self.interstitialAds removeObjectForKey:instanceId];
    return;
  }

  if ([adType isEqualToString:@"rewarded"]) {
    [self.rewardedAds removeObjectForKey:instanceId];
  }
}

- (void)emitEvent:(NSString *)adType
        adUnitId:(NSString *)adUnitId
       instanceId:(NSString *_Nullable)instanceId
             type:(NSString *)type
            error:(NSError *_Nullable)error
           reward:(NSDictionary *_Nullable)reward
             ecpm:(NSDictionary *_Nullable)ecpm {
  [self emitEvent:adType
        adUnitId:adUnitId
       instanceId:instanceId
             type:type
            error:error
        errorCode:nil
     errorMessage:nil
           reward:reward
             ecpm:ecpm];
}

- (void)emitEvent:(NSString *)adType
        adUnitId:(NSString *)adUnitId
       instanceId:(NSString *_Nullable)instanceId
             type:(NSString *)type
       errorCode:(NSNumber *_Nullable)errorCode
     errorMessage:(NSString *_Nullable)errorMessage
           reward:(NSDictionary *_Nullable)reward
             ecpm:(NSDictionary *_Nullable)ecpm {
  [self emitEvent:adType
        adUnitId:adUnitId
       instanceId:instanceId
             type:type
            error:nil
        errorCode:errorCode
     errorMessage:errorMessage
           reward:reward
             ecpm:ecpm];
}

- (void)emitEvent:(NSString *)adType
        adUnitId:(NSString *)adUnitId
       instanceId:(NSString *_Nullable)instanceId
             type:(NSString *)type
            error:(NSError *_Nullable)error
        errorCode:(NSNumber *_Nullable)errorCode
     errorMessage:(NSString *_Nullable)errorMessage
           reward:(NSDictionary *_Nullable)reward
             ecpm:(NSDictionary *_Nullable)ecpm {
  NSMutableDictionary *body = [@{
    @"type" : type,
    @"adType" : adType,
    @"adUnitId" : adUnitId ?: @"",
  } mutableCopy];

  if (instanceId.length > 0) {
    body[@"instanceId"] = instanceId;
  }

  if (error != nil) {
    body[@"error"] = @{
      @"code" : @(error.code),
      @"message" : error.localizedDescription ?: @"Unknown iOS error",
      @"platform" : @"ios",
    };
  } else if (errorCode != nil || errorMessage.length > 0) {
    body[@"error"] = @{
      @"code" : errorCode ?: @(PangleMediationErrorInvalidAdInstance),
      @"message" : errorMessage.length > 0 ? errorMessage : @"Unknown iOS error",
      @"platform" : @"ios",
    };
  }

  if (reward != nil) {
    body[@"reward"] = reward;
  }

  if (ecpm != nil) {
    body[@"ecpm"] = ecpm;
  }

  [PangleMediationEventEmitter emitEventWithBody:body];
}

- (NSDictionary *_Nullable)ecpmDictionaryForWinAd:(id<PAGMediationAdProtocol>)ad {
  if (![ad respondsToSelector:@selector(getPAGRevenuePaid)]) {
    return nil;
  }
  PAGRevenuePaid *revenuePaid = [ad getPAGRevenuePaid];
  if (revenuePaid == nil) {
    return nil;
  }
  return [self ecpmDictionaryFromInfo:[revenuePaid getWinEcpm]];
}

- (NSDictionary *_Nullable)ecpmDictionaryFromInfo:(PAGAdEcpmInfo *_Nullable)info {
  if (info == nil) {
    return nil;
  }

  NSMutableDictionary *ecpm = [NSMutableDictionary new];
  [self setStringIfPresent:ecpm key:@"country" value:info.country];
  [self setStringIfPresent:ecpm key:@"adUnit" value:info.adUnit];
  [self setStringIfPresent:ecpm key:@"adFormat" value:info.adFormat];
  [self setStringIfPresent:ecpm key:@"placement" value:info.placement];
  [self setStringIfPresent:ecpm key:@"adnName" value:info.adnName];
  ecpm[@"biddingType"] = @(info.biddingType);
  [self setStringIfPresent:ecpm key:@"currency" value:info.currency];
  [self setStringIfPresent:ecpm key:@"cpm" value:info.cpm];
  [self setStringIfPresent:ecpm key:@"revenue" value:info.revenue];
  [self setStringIfPresent:ecpm key:@"precision" value:info.precision];
  [self setStringIfPresent:ecpm key:@"segmentId" value:info.segmentID];
  [self setStringIfPresent:ecpm key:@"abTest" value:info.ABTest];
  [self setStringIfPresent:ecpm key:@"adSourceName" value:info.adSourceName];
  [self setStringIfPresent:ecpm key:@"subAdnName" value:info.subAdnName];
  [self setStringIfPresent:ecpm key:@"subSlotId" value:info.subSlotID];
  [self setStringIfPresent:ecpm key:@"creativeId" value:info.creativeID];
  return ecpm;
}

- (void)setStringIfPresent:(NSMutableDictionary *)dictionary
                       key:(NSString *)key
                     value:(NSString *_Nullable)value {
  if (value != nil) {
    dictionary[key] = value;
  }
}

- (void)emitLifecycleEventType:(NSString *)type forAd:(id<PAGAdProtocol>)ad error:(NSError *_Nullable)error {
  NSString *adType = [self adTypeForAd:ad] ?: @"";
  NSString *adUnitId = [self adUnitIdForAd:ad] ?: @"";
  NSString *instanceId = [self instanceIdForAd:ad];

  [self emitEvent:adType
          adUnitId:adUnitId
         instanceId:instanceId
               type:type
              error:error
             reward:nil
               ecpm:nil];

  if ([type isEqualToString:@"dismissed"] || [type isEqualToString:@"show_failed"]) {
    [self removeStoredAdForType:adType instanceId:instanceId];
  }
}

@end
