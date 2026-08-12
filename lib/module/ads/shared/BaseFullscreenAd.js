"use strict";

import { adEventDispatcher } from "../../internal/eventDispatcher.js";
import { extractEventPayload } from "../../internal/events.js";
let nextAdInstanceId = 0;
export function createAdInstanceId(adType, adUnitId) {
  nextAdInstanceId += 1;
  return `${adType}:${adUnitId}:${nextAdInstanceId}`;
}

// 共享拦截守卫的错误码，Android/iOS 两端统一由 JS 层裁决。
const AD_INSTANCE_IN_USE = -1;
const AD_NOT_READY = -3;
const UNKNOWN_ERROR = -4;
class PangleAdGuardError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'PangleAdGuardError';
    this.code = code;
  }
}
function toPangleMediationError(error) {
  if (error instanceof PangleAdGuardError) {
    return {
      code: error.code,
      message: error.message
    };
  }
  if (typeof error === 'object' && error != null) {
    const errorRecord = error;
    const code = typeof errorRecord.code === 'number' ? errorRecord.code : undefined;
    const message = typeof errorRecord.message === 'string' ? errorRecord.message : undefined;
    if (code != null || message != null) {
      return {
        code: code ?? UNKNOWN_ERROR,
        message: message ?? 'load_failed'
      };
    }
  }
  if (error instanceof Error) {
    return {
      code: UNKNOWN_ERROR,
      message: error.message
    };
  }
  return {
    code: UNKNOWN_ERROR,
    message: String(error)
  };
}

/**
 * 全屏广告基类。
 *
 * 事件订阅采用 AdMob 风格的两级分发拓扑：
 * - 实例构造时向全局分发器 `subscribe` 一次（按 instanceId 路由），且仅一次；
 * - 实例内部维护 `Map<type, Set<listener>>`，`addAdEventListener(type, cb)`
 *   只是往对应 type 桶里增删 listener，不再触碰底层订阅；
 * - native event 到达后按 type 直接查表分发，listener 的 payload 类型按事件
 *   type 自动收窄（失败事件为 error，奖励事件为 reward，生命周期事件为 void）。
 */
export class BaseFullscreenAd {
  // 按事件 type 建索引的实例级内部分发表。
  listeners = new Map();
  // 实例对全局分发器的唯一订阅句柄，懒挂载。
  dispatcherUnsubscribe = null;

  // 共享拦截守卫的实例状态：是否正在请求 / 是否已加载。
  state = 'idle';
  constructor(adType, adUnitId, instanceId) {
    this.adType = adType;
    this.adUnitId = adUnitId;
    this.instanceId = instanceId;
  }
  getInternalInstanceId() {
    return this.instanceId;
  }
  handleNativeEvent = event => {
    if (event.adType !== this.adType) {
      return;
    }
    // 内部状态机先于宿主监听器运行：广告关闭/展示失败/加载失败时重置守卫，
    // 即使宿主没有注册任何监听器也能恢复到可重新加载状态。
    if (event.type === 'loaded') {
      this.state = 'loaded';
    }
    if (event.type === 'dismissed' || event.type === 'show_failed' || event.type === 'load_failed') {
      this.resetToIdle();
    }
    const bucket = this.listeners.get(event.type);
    if (bucket == null || bucket.size === 0) {
      return;
    }
    const payload = extractEventPayload(event);
    // 拷贝一份，避免回调内部增删订阅导致迭代器失效。
    for (const listener of [...bucket]) {
      listener(payload);
    }
  };
  notifyLocalLoadFailed(error) {
    this.notifyLocalError('load_failed', error);
  }
  notifyLocalShowFailed(error) {
    this.notifyLocalError('show_failed', error);
  }
  notifyLocalError(type, error) {
    const bucket = this.listeners.get(type);
    if (bucket == null || bucket.size === 0) {
      return;
    }
    for (const listener of [...bucket]) {
      listener(error);
    }
  }
  ensureSubscribed() {
    if (this.dispatcherUnsubscribe == null) {
      this.dispatcherUnsubscribe = adEventDispatcher.subscribe(this.instanceId, this.handleNativeEvent);
    }
  }
  teardownIfIdle() {
    if (this.listeners.size === 0 && this.state === 'idle' && this.dispatcherUnsubscribe != null) {
      this.dispatcherUnsubscribe();
      this.dispatcherUnsubscribe = null;
    }
  }
  resetToIdle() {
    this.state = 'idle';
    this.teardownIfIdle();
  }

  /**
   * 加载守卫：拦截重复加载。
   *
   * 状态由原生事件驱动：loaded 后进入可展示状态，load_failed 后回到 idle。
   * 加载请求阶段只维护 JS 状态，不查询原生广告对象状态。
   */
  performLoad(invokeNativeLoad) {
    if (this.state !== 'idle') {
      this.notifyLocalLoadFailed(toPangleMediationError(new PangleAdGuardError(AD_INSTANCE_IN_USE, 'load() requires a unique internal ad instance while a matching ad is still loaded or loading')));
      return;
    }

    // 提前订阅，使 dismissed/show_failed/load_failed 即便无宿主监听器也能重置状态。
    this.ensureSubscribed();
    this.state = 'loading';
    try {
      invokeNativeLoad();
    } catch (error) {
      this.resetToIdle();
      this.notifyLocalLoadFailed(toPangleMediationError(error));
    }
  }

  /**
   * 展示守卫：仅拦截未加载即展示；广告是否可展示由 Pangle Mediation 原生内部判断。
   * 展示后保持 `loaded`，待 dismissed/show_failed 事件重置。
   */
  performShow(invokeNativeShow) {
    if (this.state !== 'loaded') {
      this.resetToIdle();
      this.notifyLocalShowFailed(toPangleMediationError(new PangleAdGuardError(AD_NOT_READY, 'The ad is not loaded or ready')));
      return;
    }
    try {
      invokeNativeShow();
    } catch (error) {
      this.resetToIdle();
      this.notifyLocalShowFailed(toPangleMediationError(error));
    }
  }

  /**
   * 订阅本广告实例的某一类事件，返回取消订阅函数。
   */
  addAdEventListener(type, listener) {
    this.ensureSubscribed();
    let bucket = this.listeners.get(type);
    if (bucket == null) {
      bucket = new Set();
      this.listeners.set(type, bucket);
    }
    const erased = listener;
    bucket.add(erased);
    return () => {
      const current = this.listeners.get(type);
      if (current == null) {
        return;
      }
      current.delete(erased);
      if (current.size === 0) {
        this.listeners.delete(type);
      }
      this.teardownIfIdle();
    };
  }
}
//# sourceMappingURL=BaseFullscreenAd.js.map