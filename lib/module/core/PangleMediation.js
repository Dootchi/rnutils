"use strict";

import { Platform } from 'react-native';
import NativePangleMediationReactNative from "../NativePangleMediationReactNative.js";
async function initialize(options) {
  return NativePangleMediationReactNative.initialize(options);
}
async function getSdkVersion() {
  return NativePangleMediationReactNative.getSdkVersion();
}
async function updateSegment(segment) {
  return NativePangleMediationReactNative.updateSegment(segment);
}
async function updatePrivacySettings(settings) {
  return NativePangleMediationReactNative.updatePrivacySettings(settings);
}

/**
 * Open the Pangle mediation test suite (visual debug tool).
 *
 * This is an optional debug capability. The published plugin does not bundle
 * the native test-suite dependency by default. If the host app has not added
 * the platform-specific test-suite package, this call is skipped internally.
 *
 * Requires the placement's App ID to be whitelisted by Pangle. On Android this
 * launches the test suite activity; on iOS it starts the visual debug overlay
 * when the optional native dependency is available.
 */
function openTestSuite() {
  NativePangleMediationReactNative.openTestSuite();
}
export const PangleMediation = {
  initialize,
  getSdkVersion,
  updateSegment,
  updatePrivacySettings,
  openTestSuite,
  platform: Platform.OS
};
//# sourceMappingURL=PangleMediation.js.map