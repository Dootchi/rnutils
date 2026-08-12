import type { PangleRewardedEventMap, PangleRewardedRequestOptions } from '../../types';
import { BaseFullscreenAd } from '../shared/BaseFullscreenAd';
export declare class RewardedAd extends BaseFullscreenAd<PangleRewardedEventMap> {
    private readonly requestOptions;
    static createForAdRequest(adUnitId: string, options?: PangleRewardedRequestOptions): RewardedAd;
    private constructor();
    load(): void;
    show(): void;
}
//# sourceMappingURL=RewardedAd.d.ts.map