"use strict";

export const PANGLE_MEDIATION_EVENT = 'pangleMediation:event';
/** Event types shared by interstitial and rewarded fullscreen ads. */
export let PangleAdEventType = /*#__PURE__*/function (PangleAdEventType) {
  PangleAdEventType["LOADED"] = "loaded";
  PangleAdEventType["LOAD_FAILED"] = "load_failed";
  PangleAdEventType["SHOWN"] = "shown";
  PangleAdEventType["CLICKED"] = "clicked";
  PangleAdEventType["DISMISSED"] = "dismissed";
  PangleAdEventType["REVENUE"] = "revenue";
  PangleAdEventType["SHOW_FAILED"] = "show_failed";
  return PangleAdEventType;
}({});

/** Rewarded-only event types. */
export let PangleRewardedAdEventType = /*#__PURE__*/function (PangleRewardedAdEventType) {
  PangleRewardedAdEventType["REWARD_FAILED"] = "reward_failed";
  PangleRewardedAdEventType["REWARD_EARNED"] = "reward_earned";
  return PangleRewardedAdEventType;
}({});

/**
 * 广告 eCPM / 收益信息（透传自原生 `PAGAdEcpmInfo`）。
 * 字段均为可选，因为原生 getter 可能返回空值；不同平台/聚合场景下提供的
 * 字段也不完全一致（带 `iOS only` 标注的字段仅在 iOS 上可能存在）。
 */

/**
 * 每个广告类型对外暴露的事件契约。
 * key 为事件类型，value 为该事件回调收到的 payload 类型。
 * 生命周期事件无 payload（void），失败事件携带 error，奖励事件携带 reward，
 * `loaded`/`revenue` 携带 eCPM 信息（`loaded` 取广告对象 `getWinEcpm()`，可能为空）。
 */
//# sourceMappingURL=events.js.map