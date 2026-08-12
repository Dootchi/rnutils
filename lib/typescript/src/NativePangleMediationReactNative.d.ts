import type { PangleAdRequestOptions, PangleMediationInitializationOptions, PangleMediationInitializationResult, PangleMediationSegmentInfo, PanglePrivacySettings } from './types';
export interface PangleMediationNativeModule {
    addListener(eventName: string): void;
    removeListeners(count: number): void;
    initialize(options: PangleMediationInitializationOptions): Promise<PangleMediationInitializationResult>;
    getSdkVersion(): Promise<string>;
    updateSegment(segment: PangleMediationSegmentInfo): Promise<void>;
    updatePrivacySettings(settings: PanglePrivacySettings): Promise<void>;
    loadInterstitial(adUnitId: string, instanceId: string, options: PangleAdRequestOptions): void;
    showInterstitial(instanceId: string): void;
    loadRewarded(adUnitId: string, instanceId: string, options: PangleAdRequestOptions): void;
    showRewarded(instanceId: string): void;
    /**
     * Optional native capability. Host apps may add the platform-specific test-suite
     * dependency themselves; otherwise this call is ignored internally.
     */
    openTestSuite(): void;
}
declare const _default: PangleMediationNativeModule;
export default _default;
//# sourceMappingURL=NativePangleMediationReactNative.d.ts.map