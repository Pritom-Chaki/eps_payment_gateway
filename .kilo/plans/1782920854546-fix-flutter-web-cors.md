# Fix Flutter Web CORS Failure and Modal Bottom Sheet Scroll Issue

## Problem 1: Web CORS Failure
In the Flutter web browser build, `EpsPaymentGateway.pay()` fails with:
`ClientException: Failed to fetch, uri=https://sandboxpgapi.eps.com.bd/v1/Auth/GetToken`

Cause: `package:http` uses XHR/fetch in Flutter web, which is blocked by CORS because EPS does not allow browser calls directly. Mobile works because native `HttpClient` is not CORS-restricted.

## Problem 2: Bottom Sheet Scroll Blocked
In the modal bottomsheet mode on phone, the EPS web page inside the WebView does not scroll when the user swipes up/down. Full-screen mode works.

Root cause: gesture conflict between the bottom-sheet route's drag-to-dismiss behavior and the embedded WebView's internal scrolling.

## Goal
- On mobile: keep existing behavior in full-screen mode; fix the bottom-sheet scroll issue.
- On web: eliminate all direct browser `http` calls to EPS while preserving the existing payment flow, payloads, headers (`x-hash`, `Authorization`), and public API surface.

## Scope
### In scope
- `package:eps_payment_gateway` only
- Auth (`GetToken`)
- Payment initialization (`InitializeEPS`)
- Transaction verification (`CheckMerchantTransactionStatus`)
- Modal bottomsheet behavior
- `example/lib/main.dart`
- README docs within this package

### Out of scope
- EPS server-side or CORS configuration
- Hosting requirements beyond a short proxy example
- `webview_flutter` iframe navigation inside the payment flow
- Full-screen scroll issues (none reported)

## Decisions

### D1: Proxy endpoints on web
Add `String? webAuthEndpoint` to `EpsConfig`.
If provided, all three EPS calls are forwarded instead of making direct browser fetch/XHR calls.
The proxy is expected to:
- accept the same JSON body/query parameters as the EPS endpoint,
- forward `Content-Type`, `x-hash`, and `Authorization` headers,
- return the exact same JSON shape as EPS with the same HTTP status codes.

### D2: WebView navigation unchanged on web
WebView loads the EPS `RedirectURL` in a `webview_flutter` HTML element, which performs cross-origin navigation.
Those navigations are not XHR, so they are not blocked by CORS.
Do not change the callback interception, result handling, or display modes.

### D3: Failure mode when misconfigured
If `kIsWeb` is true and `webAuthEndpoint` is null or empty at runtime, fail fast at the start of `pay()` and return `EpsPaymentStatus.error` with:
`Web mode requires a same-origin proxy endpoint because EPS does not permit browser-side HTTP requests. Set EpsConfig.webAuthEndpoint to your backend proxy URL.`

### D4: Mobile direct calls unchanged
When `!kIsWeb`, continue using `http.post` / `http.get` exactly as today.
The new field is optional and ignored on mobile.

### D5: Backend proxy contract unchanged
Proxy must preserve both:
- request payload/headers,
- response HTTP status and JSON key naming.

Affected endpoints/details:
- `POST .../v1/Auth/GetToken`
- `POST .../v1/EPSEngine/InitializeEPS`
- `GET .../v1/EPSEngine/CheckMerchantTransactionStatus?...`

### D6: Disable bottom-sheet drag on mobile
Set `showDragHandle: true` together with `enableDrag: false` on `showModalBottomSheet` for the EPS payment sheet.

Rationale:
- This removes the scroll-stealing drag-to-dismiss gesture, allowing the embedded WebView to receive vertical drags and scroll normally.
- The sheet already exposes a visible drag handle and a close button, so users still have a clear dismissal control.
- Android/iOS confirmation: both platforms honor `enableDrag`; disabling it is the lowest-risk fix.
- Preferred over attempt-to-keep-scroll+gesture-coordination because nested gesture arena conflicts with external web content are fragile and platform-dependent.

## Proposed implementation steps

### 1. Config change
In `lib/src/config/eps_config.dart`, add:
- `final String? webAuthEndpoint;`
- include it in the `const EpsConfig` constructor with a default of `null`

### 2. Auth service web branch
In `lib/src/services/eps_auth_service.dart`, update `getToken()`:
- if `kIsWeb` and `_config.webAuthEndpoint` is set, POST to `$_config.webAuthEndpoint/v1/Auth/GetToken` instead of `$_config.baseUrl/v1/Auth/GetToken`
- keep `x-hash` header and JSON body identical

### 3. API service web branches
In `lib/src/services/eps_api_service.dart`, update `initializePayment()` and `checkTransactionStatus()` similarly:
- replace `_config.baseUrl` path portion with `_config.webAuthEndpoint` on web when set
- preserve query string and headers

### 4. Fail-fast check in public `pay()`
In `lib/src/eps_payment_gateway_impl.dart`, at the start of `pay()`:
- if `kIsWeb` and `_config.webAuthEndpoint` is falsy, return `EpsPaymentResult(status: EpsPaymentStatus.error, errorMessage: <D3 message>)`

### 5. Bottom-sheet behavior change
In `lib/src/eps_payment_gateway_impl.dart`, update `_showBottomSheet`:
- pass `enableDrag: false`
- pass `showDragHandle: true`
- leave `isDismissible: true` so the back button / close icon still dispose the sheet using `Navigator.pop(context)`

### 6. Example/documentation updates
- `example/lib/main.dart`: add a comment for `webAuthEndpoint` and a note that it is required on web
- README:
  - explain web/browser CORS limit explicitly
  - add `webAuthEndpoint` to `EpsConfig` docs with the proxy requirement and sample routes
  - add a minimal proxy example showing request forwarding and response passthrough

## Validation

- Mobile:
  - confirm full-screen mode still scrolls and behaves as before
  - confirm modal bottom sheet no longer intercepts vertical drags and the WebView page scrolls
  - confirm close button still dismisses sheet
- Web (`flutter run -d chrome`):
  - without `webAuthEndpoint`, confirm clear EpsPaymentStatus.error mentioning CORS/proxy requirement
  - with `webAuthEndpoint` proxy running, confirm `pay()` reaches the EPS page instead of failing at auth
- `flutter analyze`
- optional targeted tests for:
  - web branch URL selection in auth/api services
  - missing `webAuthEndpoint` error result on web

## Risks
- Extra proxy hop on web adds latency.
- Mismatched proxy response shape will break JWT parsing or redirect URL parsing.
- If EPS changes response JSON keys, both proxy getters are affected.
- Disabling drag on bottom sheet removes one dismissal path; users who expect swipe-to-dismiss may need adjustment. Mitigated by visible close button.

## Open questions
None.
