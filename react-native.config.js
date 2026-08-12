module.exports = {
  dependency: {
    platforms: {
      ios: {},
      android: {
        packageImportPath:
          'import com.bytedance.sdk.openadsdk.mediation.rn.PangleMediationReactNativePackage;',
        packageInstance: 'new PangleMediationReactNativePackage()',
      },
    },
  },
};
