"use strict";

import { NativeModules } from 'react-native';
const LINKING_ERROR = `The package 'react-native-pangle-mediation' doesn't seem to be linked. Make sure: \n\n` + ['- You rebuilt the app after installing the package', '- You are not using Expo Go', '- CocoaPods dependencies are installed on iOS'].join('\n');
const nativeModule = NativeModules.PangleMediationReactNative;
const NativePangleMediationReactNative = nativeModule ?? new Proxy({}, {
  get() {
    throw new Error(LINKING_ERROR);
  }
});
export default NativePangleMediationReactNative;
//# sourceMappingURL=NativePangleMediationReactNative.js.map