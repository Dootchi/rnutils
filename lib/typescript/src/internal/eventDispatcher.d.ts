import type { PangleMediationNativeAdEvent } from './events';
type InstanceHandler = (event: PangleMediationNativeAdEvent) => void;
/**
 * 全局唯一的 native 事件分发器。
 *
 * 整个 JS 进程只向 NativeEventEmitter 注册一个 listener，按 instanceId 把
 * native event 路由到对应广告实例注册的处理器。每个实例只注册一个处理器
 * （实例内部再按事件 type 分发），因此这里按 instanceId 单一映射即可。
 */
declare class PangleAdEventDispatcher {
    private readonly handlers;
    private subscription;
    private getEmitter;
    private ensureSubscribed;
    private teardownIfIdle;
    /**
     * 为某个广告实例注册唯一处理器，返回取消订阅函数。
     */
    subscribe(instanceId: string, handler: InstanceHandler): () => void;
}
export declare const adEventDispatcher: PangleAdEventDispatcher;
export {};
//# sourceMappingURL=eventDispatcher.d.ts.map