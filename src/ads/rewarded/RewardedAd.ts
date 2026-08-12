import NativePangleMediationReactNative from '../../NativePangleMediationReactNative';
import type {
  PangleRewardedEventMap,
  PangleRewardedRequestOptions,
} from '../../types';

import { BaseFullscreenAd, createAdInstanceId } from '../shared/BaseFullscreenAd';

export class RewardedAd extends BaseFullscreenAd<PangleRewardedEventMap> {
  private readonly requestOptions: PangleRewardedRequestOptions;

  static createForAdRequest(
    adUnitId: string,
    options: PangleRewardedRequestOptions = {}
  ) {
    return new RewardedAd(
      adUnitId,
      createAdInstanceId('rewarded', adUnitId),
      options
    );
  }

  private constructor(
    adUnitId: string,
    instanceId: string,
    options: PangleRewardedRequestOptions
  ) {
    super('rewarded', adUnitId, instanceId);
    this.requestOptions = options;
  }

  load(): void {
    this.performLoad(
      () =>
        NativePangleMediationReactNative.loadRewarded(
          this.adUnitId,
          this.getInternalInstanceId(),
          this.requestOptions
        )
    );
  }

  show(): void {
    this.performShow(
      () =>
        NativePangleMediationReactNative.showRewarded(
          this.getInternalInstanceId()
        )
    );
  }
}
