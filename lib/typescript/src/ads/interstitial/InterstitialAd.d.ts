import type { PangleInterstitialEventMap, PangleInterstitialRequestOptions } from '../../types';
import { BaseFullscreenAd } from '../shared/BaseFullscreenAd';
export declare class InterstitialAd extends BaseFullscreenAd<PangleInterstitialEventMap> {
    private readonly requestOptions;
    static createForAdRequest(adUnitId: string, options?: PangleInterstitialRequestOptions): InterstitialAd;
    private constructor();
    load(): void;
    show(): void;
}
//# sourceMappingURL=InterstitialAd.d.ts.map