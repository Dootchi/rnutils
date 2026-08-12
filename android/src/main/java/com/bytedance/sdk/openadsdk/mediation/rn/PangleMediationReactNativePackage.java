package com.bytedance.sdk.openadsdk.mediation.rn;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@SuppressWarnings({"rawtypes", "unchecked"})
public class PangleMediationReactNativePackage implements ReactPackage {
  private PangleMediationReactNativeModule module;

  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    return Arrays.<NativeModule>asList(getOrCreateModule(reactContext));
  }

  @Override
  public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
    return Collections.<ViewManager>emptyList();
  }

  private PangleMediationReactNativeModule getOrCreateModule(ReactApplicationContext reactContext) {
    if (module == null) {
      module = new PangleMediationReactNativeModule(reactContext);
    }
    return module;
  }
}
