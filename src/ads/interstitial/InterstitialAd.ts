import NativePangleMediationReactNative from '../../NativePangleMediationReactNative';
import type {
  PangleInterstitialEventMap,
  PangleInterstitialRequestOptions,
} from '../../types';

import { BaseFullscreenAd, createAdInstanceId } from '../shared/BaseFullscreenAd';

export class InterstitialAd extends BaseFullscreenAd<PangleInterstitialEventMap> {
  private readonly requestOptions: PangleInterstitialRequestOptions;

  static createForAdRequest(
    adUnitId: string,
    options: PangleInterstitialRequestOptions = {}
  ) {
    return new InterstitialAd(
      adUnitId,
      createAdInstanceId('interstitial', adUnitId),
      options
    );
  }

  private constructor(
    adUnitId: string,
    instanceId: string,
    options: PangleInterstitialRequestOptions
  ) {
    super('interstitial', adUnitId, instanceId);
    this.requestOptions = options;
  }

  load(): void {
    this.performLoad(
      () =>
        NativePangleMediationReactNative.loadInterstitial(
          this.adUnitId,
          this.getInternalInstanceId(),
          this.requestOptions
        )
    );
  }

  show(): void {
    this.performShow(
      () =>
        NativePangleMediationReactNative.showInterstitial(
          this.getInternalInstanceId()
        )
    );
  }
}
