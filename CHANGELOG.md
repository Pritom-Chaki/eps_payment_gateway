## 1.0.1

* **New: Server Mode (`EPSMode.server`)** — Flutter calls a backend endpoint instead of EPS InitializeEPS directly. Backend returns `redirect_url` which the package opens in a WebView.
* **New: `EpsPaymentGateway.startPayment()`** — static convenience API for server mode.
* **New: `PaymentResult` / `PaymentStatus`** — simplified result model for server mode responses.
* **New: `BackendService`** — HTTP client for backend-initiated payment flow (POST init, verify, notify).
* **New: Server callback interception** — WebView monitors `https://pixposbd.com/payment/success|fail|cancel` URLs.
* **New: Error handling** — backend timeout, invalid JSON, missing `redirect_url`, WebView loading errors, SSL failures, manual close.
* **New: WebView error UI** — inline retry button when the payment page fails to load.
* **Backward compatible** — existing `EpsPaymentGateway.pay()` (Direct Mode) unchanged.
* On web, all EPS API calls are forwarded to this proxy endpoint instead of being called directly (to avoid CORS restrictions). Required when running on Flutter web; ignored on mobile.

## 1.0.0

* Initial release.
* Supports EPS sandbox and live environments.
* HMAC-SHA512 request signing.
* Full-screen and modal bottom sheet payment flows.
* Automatic token management and transaction verification.
