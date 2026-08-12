import type { PanglePrivacySettings } from './privacy';

export enum PangleSegmentGender {
  Female = 'female',
  Male = 'male',
  Unknown = 'unknown',
}

export interface PangleMediationSegmentInfo {
  userId?: string;
  channel?: string;
  subChannel?: string;
  age?: number;
  gender?: PangleSegmentGender;
  userValueGroup?: string;
  customInfos?: Record<string, string>;
}

export interface PangleMediationInitializationOptions {
  appId: string;
  debugLogEnabled?: boolean;
  /** Additional user data forwarded to supported native SDK config fields. */
  userData?: string;
  segment?: PangleMediationSegmentInfo;
  /** ADN names disabled during initialization during SDK startup. */
  setDisableInitAdn?: string[];
  /** Android only. Ignored on iOS. */
  packageName?: string;
  privacySettings?: PanglePrivacySettings;
}

export interface PangleMediationInitializationResult {
  success: boolean;
  code: string;
  message: string;
}
