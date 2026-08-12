import type { PangleAdEcpmInfo, PangleMediationAdType, PangleMediationError, PangleRewardInfo } from '../types/events';
type NativeSimpleAdEventType = 'shown' | 'clicked' | 'dismissed';
type NativeEcpmAdEventType = 'loaded' | 'revenue';
type NativeInterstitialErrorAdEventType = 'load_failed' | 'show_failed';
type NativeRewardedErrorAdEventType = NativeInterstitialErrorAdEventType | 'reward_failed';
interface PangleMediationNativeBaseAdEvent {
    adType: PangleMediationAdType;
    instanceId: string;
    adUnitId: string;
}
interface PangleInterstitialNativeLifecycleEvent extends PangleMediationNativeBaseAdEvent {
    adType: 'interstitial';
    ecpm?: undefined;
    error?: undefined;
    reward?: undefined;
    type: NativeSimpleAdEventType;
}
interface PangleInterstitialNativeEcpmEvent extends PangleMediationNativeBaseAdEvent {
    adType: 'interstitial';
    ecpm?: PangleAdEcpmInfo;
    error?: undefined;
    reward?: undefined;
    type: NativeEcpmAdEventType;
}
interface PangleInterstitialNativeErrorEvent extends PangleMediationNativeBaseAdEvent {
    adType: 'interstitial';
    ecpm?: undefined;
    error: PangleMediationError;
    reward?: undefined;
    type: NativeInterstitialErrorAdEventType;
}
interface PangleRewardedNativeLifecycleEvent extends PangleMediationNativeBaseAdEvent {
    adType: 'rewarded';
    ecpm?: undefined;
    error?: undefined;
    reward?: undefined;
    type: NativeSimpleAdEventType;
}
interface PangleRewardedNativeEcpmEvent extends PangleMediationNativeBaseAdEvent {
    adType: 'rewarded';
    ecpm?: PangleAdEcpmInfo;
    error?: undefined;
    reward?: undefined;
    type: NativeEcpmAdEventType;
}
interface PangleRewardedNativeErrorEvent extends PangleMediationNativeBaseAdEvent {
    adType: 'rewarded';
    ecpm?: undefined;
    error: PangleMediationError;
    reward?: undefined;
    type: NativeRewardedErrorAdEventType;
}
interface PangleRewardEarnedNativeEvent extends PangleMediationNativeBaseAdEvent {
    adType: 'rewarded';
    ecpm?: undefined;
    error?: undefined;
    reward: PangleRewardInfo;
    type: 'reward_earned';
}
export type PangleMediationNativeAdEvent = PangleInterstitialNativeLifecycleEvent | PangleInterstitialNativeEcpmEvent | PangleInterstitialNativeErrorEvent | PangleRewardedNativeLifecycleEvent | PangleRewardedNativeEcpmEvent | PangleRewardedNativeErrorEvent | PangleRewardEarnedNativeEvent;
/**
 * 从 native event 中提取该事件对应的回调 payload：
 * 失败事件取 error，奖励事件取 reward，`loaded`/`revenue` 取 ecpm，
 * 其余生命周期事件无 payload（undefined）。
 */
export declare function extractEventPayload(event: PangleMediationNativeAdEvent): PangleRewardInfo | PangleAdEcpmInfo | PangleMediationError | undefined;
export {};
//# sourceMappingURL=events.d.ts.map