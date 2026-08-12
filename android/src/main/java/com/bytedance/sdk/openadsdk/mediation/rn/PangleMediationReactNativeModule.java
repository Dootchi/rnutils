package com.bytedance.sdk.openadsdk.mediation.rn;

import android.app.Activity;

import androidx.annotation.Nullable;

import com.bytedance.sdk.openadsdk.api.PAGConstant;
import com.bytedance.sdk.openadsdk.api.PAGMInitSuccessModel;
import com.bytedance.sdk.openadsdk.api.PAGMUserInfoForSegment;
import com.bytedance.sdk.openadsdk.api.PAGRequest;
import com.bytedance.sdk.openadsdk.api.init.PAGMConfig;
import com.bytedance.sdk.openadsdk.api.init.PAGMSdk;
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialAd;
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialAdInteractionCallback;
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialAdLoadCallback;
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialRequest;
import com.bytedance.sdk.openadsdk.api.model.PAGAdEcpmInfo;
import com.bytedance.sdk.openadsdk.api.model.PAGErrorModel;
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardItem;
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAd;
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAdInteractionCallback;
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAdLoadCallback;
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedRequest;
import com.bytedance.sdk.openadsdk.mtestsuite.api.PAGMTestSuite;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableMap;

import java.util.concurrent.ConcurrentHashMap;

public class PangleMediationReactNativeModule extends ReactContextBaseJavaModule {
  static final String NAME = "PangleMediationReactNative";
  private static final int ERROR_INVALID_AD_INSTANCE = -1;
  private static final int ERROR_ACTIVITY_UNAVAILABLE = -2;
  private static final int ERROR_AD_NOT_FOUND = -3;

  private final ConcurrentHashMap<String, InterstitialAdEntry> interstitialAds =
      new ConcurrentHashMap<>();
  private final ConcurrentHashMap<String, RewardedAdEntry> rewardedAds =
      new ConcurrentHashMap<>();

  public PangleMediationReactNativeModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public String getName() {
    return NAME;
  }

  @ReactMethod
  public void addListener(String eventName) {
    // Required for NativeEventEmitter.
  }

  @ReactMethod
  public void removeListeners(double count) {
    // Required for NativeEventEmitter.
  }

  @ReactMethod
  public void initialize(ReadableMap options, Promise promise) {
    String appId = options.getString("appId");
    if (appId == null || appId.trim().isEmpty()) {
      promise.reject("invalid_init_options", "initialize() requires a non-empty appId");
      return;
    }

    PAGMConfig.Builder builder =
        new PAGMConfig.Builder()
            .appId(appId)
            .debugLog(ReadableMapUtils.getBooleanOrDefault(options, "debugLogEnabled", false));

    String userData = ReadableMapUtils.getStringOrNull(options, "userData");
    if (userData != null && !userData.trim().isEmpty()) {
      builder.setUserData(userData);
    }

    String packageName = ReadableMapUtils.getStringOrNull(options, "packageName");
    if (packageName != null && !packageName.trim().isEmpty()) {
      builder.setPackageName(packageName);
    }

    ReadableMap segment = ReadableMapUtils.getMapOrNull(options, "segment");
    if (segment != null) {
      PAGMUserInfoForSegment segmentInfo = resolveSegmentInfo(segment);
      if (segmentInfo != null) {
        builder.setConfigUserInfoForSegment(segmentInfo);
      }
    }

    if (options.hasKey("setDisableInitAdn") && !options.isNull("setDisableInitAdn")) {
      builder.setDisableInitAdn(
          ReadableMapUtils.toStringList(options.getArray("setDisableInitAdn")));
    }

    ReadableMap privacy = ReadableMapUtils.getMapOrNull(options, "privacySettings");
    if (privacy != null) {
      builder.setChildDirected(resolveChildDirected(privacy));
      builder.setGDPRConsent(resolveGdprConsent(privacy));
      builder.setDoNotSell(resolveDoNotSell(privacy));
      if (privacy.hasKey("paConsent") && !privacy.isNull("paConsent")) {
        builder.setPAConsent(resolvePaConsent(privacy));
      }
    }

    PAGMSdk.init(
        getReactApplicationContext(),
        builder.build(),
        new PAGMSdk.PAGMInitCallback() {
          @Override
          public void success(PAGMInitSuccessModel model) {
            WritableMap result = Arguments.createMap();
            result.putBoolean("success", true);
            result.putString("code", String.valueOf(model.getCode()));
            result.putString("message", "Pangle mediation initialized successfully");
            promise.resolve(result);
          }

          @Override
          public void fail(PAGErrorModel error) {
            promise.reject(String.valueOf(error.getErrorCode()), error.getErrorMessage());
          }
        });
  }

  @ReactMethod
  public void getSdkVersion(Promise promise) {
    promise.resolve(PAGMSdk.getMSDKVersion());
  }

  @ReactMethod
  public void updateSegment(ReadableMap segment) {
    PAGMUserInfoForSegment segmentInfo = resolveSegmentInfo(segment);
    if (segmentInfo == null) {
      return;
    }

    PAGMConfig.setUserInfoForSegment(segmentInfo);
  }

  @ReactMethod
  public void updatePrivacySettings(ReadableMap settings, Promise promise) {
    PAGMConfig.setChildDirected(resolveChildDirected(settings));
    PAGMConfig.setGDPRConsent(resolveGdprConsent(settings));
    PAGMConfig.setDoNotSell(resolveDoNotSell(settings));
    if (settings.hasKey("paConsent") && !settings.isNull("paConsent")) {
      PAGMConfig.setPAConsent(resolvePaConsent(settings));
    }
    promise.resolve(null);
  }

  @ReactMethod
  public void openTestSuite() {
    Activity currentActivity = getCurrentActivity();
    if (currentActivity == null) {
      return;
    }
    UiThreadUtil.runOnUiThread(
        () -> {
          try {
            PAGMTestSuite.launchTestSuite(currentActivity);
          } catch (Throwable throwable) {
          }
        });
  }

  @ReactMethod
  public void loadInterstitial(
      String adUnitId, String instanceId, ReadableMap options) {
    if (isBlank(instanceId)) {
      emitErrorEvent(
          "interstitial",
          adUnitId,
          instanceId,
          "load_failed",
          ERROR_INVALID_AD_INSTANCE,
          "loadInterstitial() requires a non-empty instanceId");
      return;
    }
    if (getCurrentActivity() == null) {
      emitErrorEvent(
          "interstitial",
          adUnitId,
          instanceId,
          "load_failed",
          ERROR_ACTIVITY_UNAVAILABLE,
          "An active Activity is required to load an interstitial ad");
      return;
    }

    PAGInterstitialRequest request = new PAGInterstitialRequest(getCurrentActivity());
    applyMute(request, options);
    PAGInterstitialAd.loadAd(
        adUnitId,
        request,
        new PAGInterstitialAdLoadCallback() {
          @Override
          public void onError(PAGErrorModel error) {
            emitErrorEvent("interstitial", adUnitId, instanceId, "load_failed", error);
          }

          @Override
          public void onAdLoaded(PAGInterstitialAd ad) {
            InterstitialAdEntry entry = new InterstitialAdEntry(adUnitId, instanceId, ad);
            interstitialAds.put(instanceId, entry);
            ad.setAdInteractionCallback(
                new PAGInterstitialAdInteractionCallback() {
                  @Override
                  public void onAdShowed() {
                    emitBasicEvent(entry, "shown");
                  }

                  @Override
                  public void onAdClicked() {
                    emitBasicEvent(entry, "clicked");
                  }

                  @Override
                  public void onAdDismissed() {
                    emitBasicEvent(entry, "dismissed");
                    interstitialAds.remove(entry.instanceId);
                  }

                  @Override
                  public void onAdShowFailed(PAGErrorModel error) {
                    emitErrorEvent(entry, "show_failed", error);
                    interstitialAds.remove(entry.instanceId);
                  }

                  @Override
                  public void onAdReturnRevenue(PAGAdEcpmInfo ecpmInfo) {
                    emitRevenueEvent(entry, ecpmInfo);
                  }
                });
            emitLoadedEvent(entry, ad.getWinEcpm());
          }
        });
  }

  @ReactMethod
  public void showInterstitial(String instanceId) {
    if (isBlank(instanceId)) {
      emitErrorEvent(
          "interstitial",
          "",
          instanceId,
          "show_failed",
          ERROR_INVALID_AD_INSTANCE,
          "showInterstitial() requires a non-empty instanceId");
      return;
    }

    InterstitialAdEntry entry = interstitialAds.get(instanceId);
    if (entry == null) {
      emitErrorEvent(
          "interstitial",
          "",
          instanceId,
          "show_failed",
          ERROR_AD_NOT_FOUND,
          "No cached interstitial ad for the given instance");
      return;
    }

    if (getCurrentActivity() == null) {
      emitErrorEvent(
          "interstitial",
          entry.adUnitId,
          instanceId,
          "show_failed",
          ERROR_ACTIVITY_UNAVAILABLE,
          "An active Activity is required to show an interstitial ad");
      interstitialAds.remove(entry.instanceId);
      return;
    }

    UiThreadUtil.runOnUiThread(
        () -> {
          try {
            entry.ad.show(getCurrentActivity());
          } catch (RuntimeException exception) {
            emitErrorEvent(
                "interstitial",
                entry.adUnitId,
                entry.instanceId,
                "show_failed",
                ERROR_AD_NOT_FOUND,
                exception.getMessage() == null
                    ? "Failed to show interstitial ad"
                    : exception.getMessage());
            interstitialAds.remove(entry.instanceId);
          }
        });
  }

  @ReactMethod
  public void loadRewarded(
      String adUnitId, String instanceId, ReadableMap options) {
    if (isBlank(instanceId)) {
      emitErrorEvent(
          "rewarded",
          adUnitId,
          instanceId,
          "load_failed",
          ERROR_INVALID_AD_INSTANCE,
          "loadRewarded() requires a non-empty instanceId");
      return;
    }
    if (getCurrentActivity() == null) {
      emitErrorEvent(
          "rewarded",
          adUnitId,
          instanceId,
          "load_failed",
          ERROR_ACTIVITY_UNAVAILABLE,
          "An active Activity is required to load a rewarded ad");
      return;
    }

    PAGRewardedRequest request = new PAGRewardedRequest(getCurrentActivity());
    applyMute(request, options);
    PAGRewardedAd.loadAd(
        adUnitId,
        request,
        new PAGRewardedAdLoadCallback() {
          @Override
          public void onError(PAGErrorModel error) {
            emitErrorEvent("rewarded", adUnitId, instanceId, "load_failed", error);
          }

          @Override
          public void onAdLoaded(PAGRewardedAd ad) {
            RewardedAdEntry entry = new RewardedAdEntry(adUnitId, instanceId, ad);
            rewardedAds.put(instanceId, entry);
            ad.setAdInteractionCallback(
                new PAGRewardedAdInteractionCallback() {
                  @Override
                  public void onAdShowed() {
                    emitBasicEvent(entry, "shown");
                  }

                  @Override
                  public void onAdClicked() {
                    emitBasicEvent(entry, "clicked");
                  }

                  @Override
                  public void onAdDismissed() {
                    emitBasicEvent(entry, "dismissed");
                    rewardedAds.remove(entry.instanceId);
                  }

                  @Override
                  public void onUserEarnedReward(PAGRewardItem item) {
                    PangleMediationEventEmitter.emit(
                        getReactApplicationContext(),
                        entry.adType,
                        entry.adUnitId,
                        entry.instanceId,
                        "reward_earned",
                        null,
                        item.getRewardName(),
                        item.getRewardAmount(),
                        null);
                  }

                  @Override
                  public void onUserEarnedRewardFail(PAGErrorModel error) {
                    emitErrorEvent(entry, "reward_failed", error);
                  }

                  @Override
                  public void onAdShowFailed(PAGErrorModel error) {
                    emitErrorEvent(entry, "show_failed", error);
                    rewardedAds.remove(entry.instanceId);
                  }

                  @Override
                  public void onAdReturnRevenue(PAGAdEcpmInfo ecpmInfo) {
                    emitRevenueEvent(entry, ecpmInfo);
                  }
                });
            emitLoadedEvent(entry, ad.getWinEcpm());
          }
        });
  }

  @ReactMethod
  public void showRewarded(String instanceId) {
    if (isBlank(instanceId)) {
      emitErrorEvent(
          "rewarded",
          "",
          instanceId,
          "show_failed",
          ERROR_INVALID_AD_INSTANCE,
          "showRewarded() requires a non-empty instanceId");
      return;
    }

    RewardedAdEntry entry = rewardedAds.get(instanceId);
    if (entry == null) {
      emitErrorEvent(
          "rewarded",
          "",
          instanceId,
          "show_failed",
          ERROR_AD_NOT_FOUND,
          "No cached rewarded ad for the given instance");
      return;
    }

    if (getCurrentActivity() == null) {
      emitErrorEvent(
          "rewarded",
          entry.adUnitId,
          instanceId,
          "show_failed",
          ERROR_ACTIVITY_UNAVAILABLE,
          "An active Activity is required to show a rewarded ad");
      rewardedAds.remove(entry.instanceId);
      return;
    }

    UiThreadUtil.runOnUiThread(
        () -> {
          try {
            entry.ad.show(getCurrentActivity());
          } catch (RuntimeException exception) {
            emitErrorEvent(
                "rewarded",
                entry.adUnitId,
                entry.instanceId,
                "show_failed",
                ERROR_AD_NOT_FOUND,
                exception.getMessage() == null
                    ? "Failed to show rewarded ad"
                    : exception.getMessage());
            rewardedAds.remove(entry.instanceId);
          }
        });
  }

  private void emitBasicEvent(LoadedAdEntry entry, String type) {
    PangleMediationEventEmitter.emit(
        getReactApplicationContext(),
        entry.adType,
        entry.adUnitId,
        entry.instanceId,
        type,
        null,
        null,
        null,
        null);
  }

  private void emitLoadedEvent(LoadedAdEntry entry, @Nullable PAGAdEcpmInfo ecpm) {
    PangleMediationEventEmitter.emit(
        getReactApplicationContext(),
        entry.adType,
        entry.adUnitId,
        entry.instanceId,
        "loaded",
        null,
        null,
        null,
        ecpm);
  }

  private void emitRevenueEvent(LoadedAdEntry entry, @Nullable PAGAdEcpmInfo ecpm) {
    PangleMediationEventEmitter.emit(
        getReactApplicationContext(),
        entry.adType,
        entry.adUnitId,
        entry.instanceId,
        "revenue",
        null,
        null,
        null,
        ecpm);
  }

  private void emitErrorEvent(LoadedAdEntry entry, String type, PAGErrorModel error) {
    emitErrorEvent(entry.adType, entry.adUnitId, entry.instanceId, type, error);
  }

  private void emitErrorEvent(
      String adType,
      String adUnitId,
      String instanceId,
      String type,
      PAGErrorModel error) {
    PangleMediationEventEmitter.emit(
        getReactApplicationContext(),
        adType,
        adUnitId,
        instanceId,
        type,
        error,
        null,
        null,
        null);
  }

  private void emitErrorEvent(
      String adType,
      String adUnitId,
      @Nullable String instanceId,
      String type,
      int code,
      String message) {
    PangleMediationEventEmitter.emit(
        getReactApplicationContext(),
        adType,
        adUnitId,
        instanceId,
        type,
        code,
        message,
        null,
        null,
        null);
  }

  private void applyMute(PAGRequest request, @Nullable ReadableMap options) {
    if (options != null && options.hasKey("mute") && !options.isNull("mute")) {
      request.setMute(options.getBoolean("mute"));
    }
  }

  private boolean isBlank(@Nullable String value) {
    return value == null || value.trim().isEmpty();
  }

  @Nullable
  private PAGMUserInfoForSegment resolveSegmentInfo(ReadableMap segment) {
    PAGMUserInfoForSegment.Builder builder = new PAGMUserInfoForSegment.Builder();
    boolean hasValue = false;

    String userId = ReadableMapUtils.getStringOrNull(segment, "userId");
    if (!isBlank(userId)) {
      builder.setUserId(userId);
      hasValue = true;
    }

    String channel = ReadableMapUtils.getStringOrNull(segment, "channel");
    if (!isBlank(channel)) {
      builder.setChannel(channel);
      hasValue = true;
    }

    String subChannel = ReadableMapUtils.getStringOrNull(segment, "subChannel");
    if (!isBlank(subChannel)) {
      builder.setSubChannel(subChannel);
      hasValue = true;
    }

    Integer age = ReadableMapUtils.getIntOrNull(segment, "age");
    if (age != null) {
      builder.setAge(age);
      hasValue = true;
    }

    String gender = ReadableMapUtils.getStringOrNull(segment, "gender");
    if (!isBlank(gender)) {
      builder.setGender(resolveSegmentGender(gender));
      hasValue = true;
    }

    String userValueGroup = ReadableMapUtils.getStringOrNull(segment, "userValueGroup");
    if (!isBlank(userValueGroup)) {
      builder.setUserValueGroup(userValueGroup);
      hasValue = true;
    }

    ReadableMap customInfos = ReadableMapUtils.getMapOrNull(segment, "customInfos");
    if (customInfos != null) {
      builder.setCustomInfos(ReadableMapUtils.toStringMap(customInfos));
      hasValue = true;
    }

    return hasValue ? builder.build() : null;
  }

  private String resolveSegmentGender(@Nullable String gender) {
    if (PAGMUserInfoForSegment.GENDER_FEMALE.equals(gender)) {
      return PAGMUserInfoForSegment.GENDER_FEMALE;
    }
    if (PAGMUserInfoForSegment.GENDER_MALE.equals(gender)) {
      return PAGMUserInfoForSegment.GENDER_MALE;
    }
    return PAGMUserInfoForSegment.GENDER_UNKNOWN;
  }

  private int resolveChildDirected(ReadableMap settings) {
    String childDirected = ReadableMapUtils.getStringOrNull(settings, "childDirected");
    if ("child".equals(childDirected)) {
      return PAGConstant.PAGChildDirectedType.PAG_CHILD_DIRECTED_TYPE_CHILD;
    }
    if ("nonChild".equals(childDirected)) {
      return PAGConstant.PAGChildDirectedType.PAG_CHILD_DIRECTED_TYPE_NON_CHILD;
    }
    return PAGConstant.PAGChildDirectedType.PAG_CHILD_DIRECTED_TYPE_DEFAULT;
  }

  private int resolveGdprConsent(ReadableMap settings) {
    String gdprConsent = ReadableMapUtils.getStringOrNull(settings, "gdprConsent");
    if ("noConsent".equals(gdprConsent)) {
      return PAGConstant.PAGGDPRConsentType.PAG_GDPR_CONSENT_TYPE_NO_CONSENT;
    }
    if ("consent".equals(gdprConsent)) {
      return PAGConstant.PAGGDPRConsentType.PAG_GDPR_CONSENT_TYPE_CONSENT;
    }
    return PAGConstant.PAGGDPRConsentType.PAG_GDPR_CONSENT_TYPE_DEFAULT;
  }

  private int resolveDoNotSell(ReadableMap settings) {
    String doNotSell = ReadableMapUtils.getStringOrNull(settings, "doNotSell");
    if ("sell".equals(doNotSell)) {
      return PAGConstant.PAGDoNotSellType.PAG_DO_NOT_SELL_TYPE_SELL;
    }
    if ("notSell".equals(doNotSell)) {
      return PAGConstant.PAGDoNotSellType.PAG_DO_NOT_SELL_TYPE_NOT_SELL;
    }
    return PAGConstant.PAGDoNotSellType.PAG_DO_NOT_SELL_TYPE_DEFAULT;
  }

  private int resolvePaConsent(ReadableMap settings) {
    String paConsent = ReadableMapUtils.getStringOrNull(settings, "paConsent");
    if ("consent".equals(paConsent)) {
      return PAGConstant.PAGPAConsentType.PAG_PA_CONSENT_TYPE_CONSENT;
    }
    return PAGConstant.PAGPAConsentType.PAG_PA_CONSENT_TYPE_NO_CONSENT;
  }

  private abstract static class LoadedAdEntry {
    final String adType;
    final String adUnitId;
    final String instanceId;

    LoadedAdEntry(String adType, String adUnitId, String instanceId) {
      this.adType = adType;
      this.adUnitId = adUnitId;
      this.instanceId = instanceId;
    }
  }

  private static final class InterstitialAdEntry extends LoadedAdEntry {
    final PAGInterstitialAd ad;

    InterstitialAdEntry(String adUnitId, String instanceId, PAGInterstitialAd ad) {
      super("interstitial", adUnitId, instanceId);
      this.ad = ad;
    }
  }

  private static final class RewardedAdEntry extends LoadedAdEntry {
    final PAGRewardedAd ad;

    RewardedAdEntry(String adUnitId, String instanceId, PAGRewardedAd ad) {
      super("rewarded", adUnitId, instanceId);
      this.ad = ad;
    }
  }
}
