# react-native-pangle-mediation

React Native classic-bridge integration for the **Pangle Mediation SDK**.

## Current status

This repository currently ships:

- a React Native library scaffold
- Android and iOS native integration for SDK initialization, privacy settings, interstitial ads, and rewarded ads
- an example app that exercises the current fullscreen ad APIs
- setup and validation docs under `docs/`

The library currently uses the classic React Native native-module/event-emitter bridge. The example app keeps React Native New Architecture disabled while this package remains on the classic bridge path.

## Supported API surface

### Core

- `PangleMediation.initialize(options)`
- `PangleMediation.getSdkVersion()`
- `PangleMediation.updatePrivacySettings(settings)`
- `PangleMediation.openTestSuite()` *(optional debug capability; requires host-app native test-suite dependency)*
- `PangleMediation.onAdEvent(listener)`

### Ad formats currently exported from the package entrypoint

- `InterstitialAd`
- `RewardedAd`

Fullscreen events include:

- `adType`
- `adUnitId`
- optional `error`
- optional `reward`
- optional `ecpm` (`PangleAdEcpmInfo`; carried by `loaded` via `getWinEcpm()` and by `revenue` from `onAdReturnRevenue`)

## Optional test-suite integration

The published plugin does **not** bundle the native Pangle mediation test-suite dependency.

- Business apps integrating this package do not need to install the test suite unless they want demo/debug access to it.
- The example app wires the native test-suite dependency separately for demo/debug use.
- If the host app has not added the native dependency, `openTestSuite()` is skipped internally and does not surface an error to app code.
- `openTestSuite()` is a fire-and-forget call and does not return a Promise.

## Quick start

Install repo dependencies:

```bash
node .yarn/releases/yarn-4.11.0.cjs install
```

Configure example IDs:

- `example/src/config/pangle.ts`

Run typecheck:

```bash
node .yarn/releases/yarn-4.11.0.cjs typecheck
```

Run tests:

```bash
node .yarn/releases/yarn-4.11.0.cjs test
```

Run the example app:

```bash
node .yarn/releases/yarn-4.11.0.cjs example android
```

For iOS, install example pods first:

```bash
cd example
bundle install
bundle exec pod install
```

## Docs

- `docs/android.md`
- `docs/ios.md`
- `docs/api.md`
- `docs/demo-validation.md`

## Known limitations

- The current public JS entrypoint exports fullscreen ads only (`InterstitialAd`, `RewardedAd`)
- The library still uses the classic bridge rather than TurboModule/codegen-native fullscreen APIs
- iOS SKAdNetwork IDs must still be added per mediated network
- The pinned iOS pod version should be revalidated against the latest internal release before shipping
