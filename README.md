# eps_payment_gateway

A Flutter package for integrating the **EPS (Easy Payment System)** payment gateway into your Flutter application. Supports **sandbox** and **live** environments, handles HMAC-SHA512 request signing, JWT authentication, and transaction verification automatically.

**Supported payment methods:** Visa · Mastercard · American Express · bKash · Nagad · Rocket · and more.

---

## Features

- **Two integration modes:**
  - **Direct Mode** — Flutter calls EPS APIs directly (original flow).
  - **Server Mode** — Flutter calls your backend which proxies to EPS (recommended for production).
- One-call payment flow — `EpsPaymentGateway.pay()` (direct) or `EpsPaymentGateway.startPayment()` (server)
- Full-screen page **or** modal bottom sheet display modes
- Automatic HMAC-SHA512 `x-hash` signing on every request (direct mode)
- Automatic JWT token acquisition (direct mode)
- Post-payment transaction verification (direct mode)
- Sandbox and live environment toggle
- Auto-detects platform (Android / iOS / Web) for the correct `transactionTypeId`
- **Web proxy support** — routes browser HTTP calls through your backend to avoid CORS

---

## Installation

```yaml
dependencies:
  eps_payment_gateway: ^1.0.0
```

### Android

Add internet permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

---

## Quick Start

### Direct Mode (Flutter calls EPS directly)

Use this when your Flutter app communicates directly with EPS APIs.

```dart
import 'package:eps_payment_gateway/eps_payment_gateway.dart';

// 1. Create the gateway once (e.g. in a service or provider).
final eps = EpsPaymentGateway(
  config: EpsConfig(
    merchantId: 'your-merchant-id',
    storeId:    'your-store-id',
    hashKey:    'your-hash-key',
    userName:   'your@email.com',
    password:   'yourPassword',
    environment: EpsEnvironment.sandbox, // switch to .live for production
  ),
);

// 2. Call pay() from a widget.
Future<void> checkout(BuildContext context) async {
  final result = await eps.pay(
    context: context,
    order: EpsOrder(
      orderId:         'ORDER-001',
      amount:          150.00,
      customerName:    'Rahim Uddin',
      customerEmail:   'rahim@example.com',
      customerPhone:   '01712345678',
      customerAddress: 'Uttara, Dhaka',
      customerCity:    'Dhaka',
      customerPostcode:'1230',
      products: [
        EpsProduct(name: 'T-Shirt', quantity: 2, price: 75.00),
      ],
    ),
    mode: EpsDisplayMode.modalBottomSheet, // or .fullScreen
  );

  // 3. Handle the result.
  switch (result.status) {
    case EpsPaymentStatus.success:
      print('Paid! EPS TXN: ${result.epsTransactionId}');
    case EpsPaymentStatus.failed:
      print('Payment failed: ${result.errorMessage}');
    case EpsPaymentStatus.cancelled:
      print('User cancelled.');
    case EpsPaymentStatus.error:
      print('Error: ${result.errorMessage}');
  }
}
```

### Server Mode (Flutter calls your backend)

Use this when your backend proxies the InitializeEPS call. This is the **recommended approach for production** because EPS validates the request origin and only accepts requests from the registered merchant domain.

```dart
import 'package:eps_payment_gateway/eps_payment_gateway.dart';

Future<void> checkout(BuildContext context) async {
  final result = await EpsPaymentGateway.startPayment(
    context: context,
    mode: EPSMode.server,
    initUrl: 'https://pixposbd.com/api/eps/init',
    requestBody: {
      'invoice_no': 'INV-001',
      'amount': 500,
      'customer_name': 'Rahim Uddin',
      'customer_phone': '01712345678',
      'customer_email': 'rahim@example.com',
    },
    displayMode: EpsDisplayMode.fullScreen,
  );

  // Handle the result.
  switch (result.status) {
    case PaymentStatus.success:
      print('Paid! TXN: ${result.transactionId}');
    case PaymentStatus.failed:
      print('Payment failed: ${result.message}');
    case PaymentStatus.cancelled:
      print('User cancelled: ${result.message}');
  }
}
```

#### Expected Backend Response

Your backend endpoint (`initUrl`) must return:

```json
{
    "success": true,
    "redirect_url": "https://payment.eps.com.bd/..."
}
```

On failure:

```json
{
    "success": false,
    "message": "Error description"
}
```

#### Callback URLs

The WebView monitors these URLs and closes automatically when one is detected:

| URL | Payment Status |
|---|---|
| `https://pixposbd.com/payment/success` | success |
| `https://pixposbd.com/payment/fail` | failed |
| `https://pixposbd.com/payment/cancel` | cancelled |

Your backend should redirect the EPS payment page to one of these URLs after processing the payment.

---

## Display Modes

| Mode | Description |
|---|---|
| `EpsDisplayMode.fullScreen` | Pushes a full-screen `Scaffold` with an app bar |
| `EpsDisplayMode.modalBottomSheet` | Slides up a bottom sheet at 92% of screen height |

---

## API Reference

### `EpsConfig`

| Property | Type | Required | Description |
|---|---|---|---|
| `merchantId` | `String` | ✅ | Your EPS merchant UUID |
| `storeId` | `String` | ✅ | Your EPS store UUID |
| `hashKey` | `String` | ✅ | Secret key for HMAC-SHA512 signing |
| `userName` | `String` | ✅ | EPS merchant login email |
| `password` | `String` | ✅ | EPS merchant login password |
| `environment` | `EpsEnvironment` | | `.live` (default) or `.sandbox` |
| `webAuthEndpoint` | `String?` | | On Flutter web, your backend proxy URL. Required on web (CORS workaround). |

### `EpsOrder`

| Property | Type | Required | Description |
|---|---|---|---|
| `orderId` | `String` | ✅ | Your unique order ID |
| `amount` | `double` | ✅ | Payment amount |
| `customerName` | `String` | ✅ | |
| `customerEmail` | `String` | ✅ | |
| `customerPhone` | `String` | ✅ | |
| `customerAddress` | `String` | ✅ | |
| `customerCity` | `String` | ✅ | |
| `customerPostcode` | `String` | ✅ | |
| `products` | `List<EpsProduct>` | | Product line items |
| `merchantTransactionId` | `String?` | | Auto-generated if omitted (>= 10 digits) |
| `transactionTypeId` | `int?` | | 1=Web, 2=Android, 3=iOS. Auto-detected if omitted |

### `EpsPaymentResult` (Direct Mode)

| Property | Type | Description |
|---|---|---|
| `status` | `EpsPaymentStatus` | `success`, `failed`, `cancelled`, `error` |
| `isSuccess` | `bool` | Convenience getter |
| `merchantTransactionId` | `String?` | Your transaction ID |
| `epsTransactionId` | `String?` | EPS-assigned transaction ID |
| `errorMessage` | `String?` | Error description if applicable |
| `details` | `EpsTransactionStatus?` | Full verification response |

### `PaymentResult` (Server Mode)

| Property | Type | Description |
|---|---|---|
| `status` | `PaymentStatus` | `success`, `failed`, `cancelled` |
| `transactionId` | `String?` | Transaction identifier from the backend |
| `message` | `String?` | Human-readable result message |

### `EPSMode`

| Value | Description |
|---|---|
| `EPSMode.direct` | Flutter calls EPS APIs directly using merchant credentials |
| `EPSMode.server` | Flutter calls a backend endpoint, which proxies to EPS |

---

## Environments

| Environment | API Base URL |
|---|---|
| `EpsEnvironment.sandbox` | `https://sandboxpgapi.eps.com.bd` |
| `EpsEnvironment.live` | `https://pgapi.eps.com.bd` |

Sandbox credentials are available from the [EPS merchant portal](https://merchant.eps.com.bd).

---

## Web / CORS

When running on Flutter web, the browser's XHR/fetch is blocked by EPS's CORS policy. To work around this, set `webAuthEndpoint` to your backend proxy URL:

```dart
config: const EpsConfig(
  // ... other fields
  webAuthEndpoint: 'https://your-backend.com/api/proxy',
),
```

Your proxy must forward requests to EPS and return the same response shape.

### Minimal Node.js Proxy Example

```js
// server.js (Express)
app.use('/api/proxy', async (req, res) => {
  const epsUrl = 'https://sandboxpgapi.eps.com.bd' + req.url;
  const response = await fetch(epsUrl, {
    method: req.method,
    headers: {
      'Content-Type': req.headers['content-type'],
      'Authorization': req.headers['authorization'],
      'x-hash': req.headers['x-hash'],
    },
    body: req.body,
  });
  const data = await response.json();
  res.status(response.status).json(data);
});
```

---

## How It Works

### Direct Mode

```
Your App
  │
  ├─ 1. EpsPaymentGateway.pay()
  │       POST /v1/Auth/GetToken          → JWT token
  │       POST /v1/EPSEngine/InitializeEPS → RedirectURL
  │
  ├─ 2. Opens RedirectURL in WebView
  │       User selects payment method and completes payment
  │
  ├─ 3. EPS redirects to internal callback URL
  │       WebView intercepts it (page never loads)
  │
  └─ 4. GET /v1/EPSEngine/CheckMerchantTransactionStatus
          Returns EpsPaymentResult to your code
```

### Server Mode

```
Your App                            Your Backend
  │                                     │
  ├─ 1. EpsPaymentGateway.startPayment()
  │       POST /api/eps/init            │
  │  ──────────────────────────────────>│
  │       POST /v1/EPSEngine/InitializeEPS
  │       (your server calls EPS)       │
  │  <──────────────────────────────────│
  │       { redirect_url: "..." }       │
  │                                     │
  ├─ 2. Opens redirect_url in WebView
  │       User selects payment method and completes payment
  │
  ├─ 3. EPS redirects to your callback URL
  │       (success / fail / cancel)
  │       WebView intercepts it (page never loads)
  │
  └─ 4. Returns PaymentResult to your code
```

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| Backend timeout (30s) | Returns `PaymentStatus.cancelled` with timeout message |
| Invalid JSON from backend | Returns `PaymentStatus.cancelled` with parse error message |
| `redirect_url` missing | Returns `PaymentStatus.cancelled` |
| WebView loading error | Shows retry button inline, does not close automatically |
| SSL/TLS error | WebView shows error, user can retry |
| User closes WebView | Returns `PaymentStatus.cancelled` |
| Network unavailable | WebView shows error, user can retry |

---

## License

MIT © [Pritom Chaki](https://github.com/Pritom-Chaki)
