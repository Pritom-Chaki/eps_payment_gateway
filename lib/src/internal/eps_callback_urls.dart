// Internal callback URLs sent to EPS as successUrl / failUrl / cancelUrl.
// The WebView's NavigationDelegate intercepts these before they load.
const kEpsSuccessCallbackUrl = 'https://eps-callback.internal/success';
const kEpsFailCallbackUrl = 'https://eps-callback.internal/fail';
const kEpsCancelCallbackUrl = 'https://eps-callback.internal/cancel';
