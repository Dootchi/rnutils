import type { PangleAdEventListener, PangleMediationAdType } from '../../types/events';
export declare function createAdInstanceId(adType: PangleMediationAdType, adUnitId: string): string;
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
export declare abstract class BaseFullscreenAd<TEventMap> {
    protected readonly adUnitId: string;
    private readonly adType;
    private readonly instanceId;
    private readonly listeners;
    private dispatcherUnsubscribe;
    private state;
    protected constructor(adType: PangleMediationAdType, adUnitId: string, instanceId: string);
    protected getInternalInstanceId(): string;
    private handleNativeEvent;
    private notifyLocalLoadFailed;
    private notifyLocalShowFailed;
    private notifyLocalError;
    private ensureSubscribed;
    private teardownIfIdle;
    private resetToIdle;
    /**
     * 加载守卫：拦截重复加载。
     *
     * 状态由原生事件驱动：loaded 后进入可展示状态，load_failed 后回到 idle。
     * 加载请求阶段只维护 JS 状态，不查询原生广告对象状态。
     */
    protected performLoad(invokeNativeLoad: () => void): void;
    /**
     * 展示守卫：仅拦截未加载即展示；广告是否可展示由 Pangle Mediation 原生内部判断。
     * 展示后保持 `loaded`，待 dismissed/show_failed 事件重置。
     */
    protected performShow(invokeNativeShow: () => void): void;
    /**
     * 订阅本广告实例的某一类事件，返回取消订阅函数。
     */
    addAdEventListener<K extends keyof TEventMap & string>(type: K, listener: PangleAdEventListener<TEventMap, K>): () => void;
}
//# sourceMappingURL=BaseFullscreenAd.d.ts.map