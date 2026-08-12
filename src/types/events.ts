export const PANGLE_MEDIATION_EVENT = 'pangleMediation:event';

export type PangleMediationAdType = 'interstitial' | 'rewarded';

/** Event types shared by interstitial and rewarded fullscreen ads. */
export enum PangleAdEventType {
  LOADED = 'loaded',
  LOAD_FAILED = 'load_failed',
  SHOWN = 'shown',
  CLICKED = 'clicked',
  DISMISSED = 'dismissed',
  REVENUE = 'revenue',
  SHOW_FAILED = 'show_failed',
}

/** Rewarded-only event types. */
export enum PangleRewardedAdEventType {
  REWARD_FAILED = 'reward_failed',
  REWARD_EARNED = 'reward_earned',
}

export type PangleMediationAdEventType =
  | `${PangleAdEventType}`
  | `${PangleRewardedAdEventType}`;

export interface PangleRewardInfo {
  amount: number;
  name: string;
}

/**
 * 广告 eCPM / 收益信息（透传自原生 `PAGAdEcpmInfo`）。
 * 字段均为可选，因为原生 getter 可能返回空值；不同平台/聚合场景下提供的
 * 字段也不完全一致（带 `iOS only` 标注的字段仅在 iOS 上可能存在）。
 */
export interface PangleAdEcpmInfo {
  country?: string;
  adUnit?: string;
  adFormat?: string;
  placement?: string;
  adnName?: string;
  biddingType?: number;
  currency?: string;
  cpm?: string;
  revenue?: string;
  precision?: string;
  segmentId?: string;
  abTest?: string;
  /** iOS only */
  adSourceName?: string;
  /** iOS only */
  subAdnName?: string;
  /** iOS only */
  subSlotId?: string;
  /** iOS only */
  creativeId?: string;
}

export interface PangleMediationError {
  code: number;
  message: string;
  platform?: 'android' | 'ios';
}

/**
 * 每个广告类型对外暴露的事件契约。
 * key 为事件类型，value 为该事件回调收到的 payload 类型。
 * 生命周期事件无 payload（void），失败事件携带 error，奖励事件携带 reward，
 * `loaded`/`revenue` 携带 eCPM 信息（`loaded` 取广告对象 `getWinEcpm()`，可能为空）。
 */
export interface PangleInterstitialEventMap {
  loaded: PangleAdEcpmInfo | undefined;
  shown: void;
  clicked: void;
  dismissed: void;
  revenue: PangleAdEcpmInfo;
  load_failed: PangleMediationError;
  show_failed: PangleMediationError;
}

export interface PangleRewardedEventMap {
  loaded: PangleAdEcpmInfo | undefined;
  shown: void;
  clicked: void;
  dismissed: void;
  revenue: PangleAdEcpmInfo;
  load_failed: PangleMediationError;
  show_failed: PangleMediationError;
  reward_failed: PangleMediationError;
  reward_earned: PangleRewardInfo;
}

export type PangleAdEventMap =
  | PangleInterstitialEventMap
  | PangleRewardedEventMap;

export type PangleAdEventListener<
  TEventMap,
  K extends keyof TEventMap,
> = (payload: TEventMap[K]) => void;
