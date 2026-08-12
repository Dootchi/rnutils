import { NativeModules } from 'react-native';

import type {
  PangleAdRequestOptions,
  PangleMediationInitializationOptions,
  PangleMediationInitializationResult,
  PangleMediationSegmentInfo,
  PanglePrivacySettings,
} from './types';

export interface PangleMediationNativeModule {
  addListener(eventName: string): void;
  removeListeners(count: number): void;
  initialize(
    options: PangleMediationInitializationOptions
  ): Promise<PangleMediationInitializationResult>;
  getSdkVersion(): Promise<string>;
  updateSegment(segment: PangleMediationSegmentInfo): Promise<void>;
  updatePrivacySettings(settings: PanglePrivacySettings): Promise<void>;
  loadInterstitial(
    adUnitId: string,
    instanceId: string,
    options: PangleAdRequestOptions
  ): void;
  showInterstitial(instanceId: string): void;
  loadRewarded(
    adUnitId: string,
    instanceId: string,
    options: PangleAdRequestOptions
  ): void;
  showRewarded(instanceId: string): void;
  /**
   * Optional native capability. Host apps may add the platform-specific test-suite
   * dependency themselves; otherwise this call is ignored internally.
   */
  openTestSuite(): void;
}

const LINKING_ERROR =
  `The package 'react-native-pangle-mediation' doesn't seem to be linked. Make sure: \n\n` +
  [
    '- You rebuilt the app after installing the package',
    '- You are not using Expo Go',
    '- CocoaPods dependencies are installed on iOS',
  ].join('\n');

const nativeModule = NativeModules.PangleMediationReactNative as
  | PangleMediationNativeModule
  | undefined;

const NativePangleMediationReactNative =
  nativeModule ??
  new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );

export default NativePangleMediationReactNative as PangleMediationNativeModule;
