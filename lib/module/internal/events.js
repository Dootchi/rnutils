"use strict";

/**
 * 从 native event 中提取该事件对应的回调 payload：
 * 失败事件取 error，奖励事件取 reward，`loaded`/`revenue` 取 ecpm，
 * 其余生命周期事件无 payload（undefined）。
 */
export function extractEventPayload(event) {
  if (event.error != null) {
    return event.error;
  }
  if (event.reward != null) {
    return event.reward;
  }
  if (event.type === 'loaded' || event.type === 'revenue') {
    return event.ecpm;
  }
  return undefined;
}
//# sourceMappingURL=events.js.map