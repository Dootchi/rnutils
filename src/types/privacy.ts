export enum PangleChildDirected {
  Default = 'default',
  Child = 'child',
  NonChild = 'nonChild',
}

export enum PangleGdprConsent {
  Default = 'default',
  NoConsent = 'noConsent',
  Consent = 'consent',
}

export enum PangleDoNotSell {
  Default = 'default',
  Sell = 'sell',
  NotSell = 'notSell',
}

export enum PanglePaConsent {
  NoConsent = 'noConsent',
  Consent = 'consent',
}

export interface PanglePrivacySettings {
  childDirected?: PangleChildDirected;
  gdprConsent?: PangleGdprConsent;
  doNotSell?: PangleDoNotSell;
  paConsent?: PanglePaConsent;
}
