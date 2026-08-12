"use strict";

import { NativeEventEmitter, NativeModules } from 'react-native';
import NativePangleMediationReactNative from "../NativePangleMediationReactNative.js";
import { PANGLE_MEDIATION_EVENT } from "../types/events.js";
/**
 * 全局唯一的 native 事件分发器。
 *
 * 整个 JS 进程只向 NativeEventEmitter 注册一个 listener，按 instanceId 把
 * native event 路由到对应广告实例注册的处理器。每个实例只注册一个处理器
 * （实例内部再按事件 type 分发），因此这里按 instanceId 单一映射即可。
 */
class PangleAdEventDispatcher {
  handlers = new Map();
  subscription = null;
  getEmitter() {
    return new NativeEventEmitter(NativeModules.PangleMediationEventEmitter ?? NativePangleMediationReactNative);
  }
  ensureSubscribed() {
    if (this.subscription != null) {
      return;
    }
    this.subscription = this.getEmitter().addListener(PANGLE_MEDIATION_EVENT, event => {
      this.handlers.get(event.instanceId)?.(event);
    });
  }
  teardownIfIdle() {
    if (this.handlers.size === 0 && this.subscription != null) {
      this.subscription.remove();
      this.subscription = null;
    }
  }

  /**
   * 为某个广告实例注册唯一处理器，返回取消订阅函数。
   */
  subscribe(instanceId, handler) {
    this.ensureSubscribed();
    this.handlers.set(instanceId, handler);
    return () => {
      if (this.handlers.get(instanceId) === handler) {
        this.handlers.delete(instanceId);
        this.teardownIfIdle();
      }
    };
  }
}
export const adEventDispatcher = new PangleAdEventDispatcher();
//# sourceMappingURL=eventDispatcher.js.map