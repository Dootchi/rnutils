import type { PangleMediationInitializationOptions, PangleMediationInitializationResult, PangleMediationSegmentInfo, PanglePrivacySettings } from '../types';
declare function initialize(options: PangleMediationInitializationOptions): Promise<PangleMediationInitializationResult>;
declare function getSdkVersion(): Promise<string>;
declare function updateSegment(segment: PangleMediationSegmentInfo): Promise<void>;
declare function updatePrivacySettings(settings: PanglePrivacySettings): Promise<void>;
/**
 * Open the Pangle mediation test suite (visual debug tool).
 *
 * This is an optional debug capability. The published plugin does not bundle
 * the native test-suite dependency by default. If the host app has not added
 * the platform-specific test-suite package, this call is skipped internally.
 *
 * Requires the placement's App ID to be whitelisted by Pangle. On Android this
 * launches the test suite activity; on iOS it starts the visual debug overlay
 * when the optional native dependency is available.
 */
declare function openTestSuite(): void;
export declare const PangleMediation: {
    initialize: typeof initialize;
    getSdkVersion: typeof getSdkVersion;
    updateSegment: typeof updateSegment;
    updatePrivacySettings: typeof updatePrivacySettings;
    openTestSuite: typeof openTestSuite;
    platform: "android" | "ios" | "windows" | "macos" | "web";
};
export type PangleMediationStatic = typeof PangleMediation;
export {};
//# sourceMappingURL=PangleMediation.d.ts.map