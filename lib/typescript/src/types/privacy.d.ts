export declare enum PangleChildDirected {
    Default = "default",
    Child = "child",
    NonChild = "nonChild"
}
export declare enum PangleGdprConsent {
    Default = "default",
    NoConsent = "noConsent",
    Consent = "consent"
}
export declare enum PangleDoNotSell {
    Default = "default",
    Sell = "sell",
    NotSell = "notSell"
}
export declare enum PanglePaConsent {
    NoConsent = "noConsent",
    Consent = "consent"
}
export interface PanglePrivacySettings {
    childDirected?: PangleChildDirected;
    gdprConsent?: PangleGdprConsent;
    doNotSell?: PangleDoNotSell;
    paConsent?: PanglePaConsent;
}
//# sourceMappingURL=privacy.d.ts.map