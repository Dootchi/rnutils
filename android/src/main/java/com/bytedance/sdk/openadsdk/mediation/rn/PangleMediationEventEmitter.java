package com.bytedance.sdk.openadsdk.mediation.rn;

import androidx.annotation.Nullable;

import com.bytedance.sdk.openadsdk.api.model.PAGAdEcpmInfo;
import com.bytedance.sdk.openadsdk.api.model.PAGErrorModel;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

public final class PangleMediationEventEmitter {
  public static final String EVENT_NAME = "pangleMediation:event";

  private PangleMediationEventEmitter() {}

  public static void emit(
      ReactApplicationContext reactContext,
      String adType,
      String adUnitId,
      @Nullable String instanceId,
      String type,
      @Nullable PAGErrorModel error,
      @Nullable String rewardName,
      @Nullable Integer rewardAmount,
      @Nullable PAGAdEcpmInfo ecpm) {
    emit(
        reactContext,
        adType,
        adUnitId,
        instanceId,
        type,
        error == null ? null : error.getErrorCode(),
        error == null ? null : error.getErrorMessage(),
        rewardName,
        rewardAmount,
        ecpm);
  }

  public static void emit(
      ReactApplicationContext reactContext,
      String adType,
      String adUnitId,
      @Nullable String instanceId,
      String type,
      @Nullable Integer errorCode,
      @Nullable String errorMessage,
      @Nullable String rewardName,
      @Nullable Integer rewardAmount,
      @Nullable PAGAdEcpmInfo ecpm) {
    if (!reactContext.hasActiveReactInstance()) {
      return;
    }

    WritableMap payload = Arguments.createMap();
    payload.putString("type", type);
    payload.putString("adType", adType);
    payload.putString("adUnitId", adUnitId);

    if (instanceId != null) {
      payload.putString("instanceId", instanceId);
    }
    if (errorCode != null || errorMessage != null) {
      WritableMap error = Arguments.createMap();
      error.putInt("code", errorCode == null ? -1 : errorCode);
      error.putString(
          "message", errorMessage == null ? "Unknown Android error" : errorMessage);
      error.putString("platform", "android");
      payload.putMap("error", error);
    }
    if (rewardName != null && rewardAmount != null) {
      WritableMap rewardMap = Arguments.createMap();
      rewardMap.putString("name", rewardName);
      rewardMap.putInt("amount", rewardAmount);
      payload.putMap("reward", rewardMap);
    }
    if (ecpm != null) {
      payload.putMap("ecpm", buildEcpmMap(ecpm));
    }

    reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(EVENT_NAME, payload);
  }

  private static WritableMap buildEcpmMap(PAGAdEcpmInfo ecpm) {
    WritableMap ecpmMap = Arguments.createMap();
    putStringIfPresent(ecpmMap, "country", ecpm.getCountry());
    putStringIfPresent(ecpmMap, "adUnit", ecpm.getAdUnit());
    putStringIfPresent(ecpmMap, "adFormat", ecpm.getAdFormat());
    putStringIfPresent(ecpmMap, "placement", ecpm.getPlacement());
    putStringIfPresent(ecpmMap, "adnName", ecpm.getAdnName());
    ecpmMap.putInt("biddingType", ecpm.getBiddingType());
    putStringIfPresent(ecpmMap, "currency", ecpm.getCurrency());
    putStringIfPresent(ecpmMap, "cpm", ecpm.getCpm());
    putStringIfPresent(ecpmMap, "revenue", ecpm.getRevenue());
    putStringIfPresent(ecpmMap, "precision", ecpm.getPrecision());
    putStringIfPresent(ecpmMap, "segmentId", ecpm.getSegmentID());
    putStringIfPresent(ecpmMap, "abTest", ecpm.getABTest());
    return ecpmMap;
  }

  private static void putStringIfPresent(
      WritableMap map, String key, @Nullable String value) {
    if (value != null) {
      map.putString(key, value);
    }
  }
}
