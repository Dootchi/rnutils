"use strict";

import NativePangleMediationReactNative from "../../NativePangleMediationReactNative.js";
import { BaseFullscreenAd, createAdInstanceId } from "../shared/BaseFullscreenAd.js";
export class InterstitialAd extends BaseFullscreenAd {
  static createForAdRequest(adUnitId, options = {}) {
    return new InterstitialAd(adUnitId, createAdInstanceId('interstitial', adUnitId), options);
  }
  constructor(adUnitId, instanceId, options) {
    super('interstitial', adUnitId, instanceId);
    this.requestOptions = options;
  }
  load() {
    this.performLoad(() => NativePangleMediationReactNative.loadInterstitial(this.adUnitId, this.getInternalInstanceId(), this.requestOptions));
  }
  show() {
    this.performShow(() => NativePangleMediationReactNative.showInterstitial(this.getInternalInstanceId()));
  }
}
//# sourceMappingURL=InterstitialAd.js.map