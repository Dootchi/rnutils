"use strict";

import NativePangleMediationReactNative from "../../NativePangleMediationReactNative.js";
import { BaseFullscreenAd, createAdInstanceId } from "../shared/BaseFullscreenAd.js";
export class RewardedAd extends BaseFullscreenAd {
  static createForAdRequest(adUnitId, options = {}) {
    return new RewardedAd(adUnitId, createAdInstanceId('rewarded', adUnitId), options);
  }
  constructor(adUnitId, instanceId, options) {
    super('rewarded', adUnitId, instanceId);
    this.requestOptions = options;
  }
  load() {
    this.performLoad(() => NativePangleMediationReactNative.loadRewarded(this.adUnitId, this.getInternalInstanceId(), this.requestOptions));
  }
  show() {
    this.performShow(() => NativePangleMediationReactNative.showRewarded(this.getInternalInstanceId()));
  }
}
//# sourceMappingURL=RewardedAd.js.map