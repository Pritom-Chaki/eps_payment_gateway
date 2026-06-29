# eps_payment_gateway

A Flutter package for integrating the **EPS (Easy Payment System)** payment gateway into your Flutter application. Supports **sandbox** and **live** environments, handles HMAC-SHA512 request signing, JWT authentication, and transaction verification automatically.

**Supported payment methods:** Visa · Mastercard · American Express · bKash · Nagad · Rocket · and more.

---

## Features

- One-call payment flow — `EpsPaymentGateway.pay()`
- Full-screen page **or** modal bottom sheet display modes
- Automatic HMAC-SHA512 `x-hash` signing on every request
- Automatic JWT token acquisition
- Post-payment transaction verification
- Sandbox and live environment toggle
- Auto-detects platform (Android / iOS / Web) for the correct `transactionTypeId`
- Typed result: `success`, `failed`, `cancelled`, `error` — never throws

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

---

## Display Modes

| Mode | Description |
|---|---|
| `EpsDisplayMode.fullScreen` | Pushes a full-screen `Scaffold` with an app bar |
| `EpsDisplayMode.modalBottomSheet` | Slides up a bottom sheet at 92 % of screen height |

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
| `merchantTransactionId` | `String?` | | Auto-generated if omitted (≥ 10 digits) |
| `transactionTypeId` | `int?` | | 1=Web, 2=Android, 3=iOS. Auto-detected if omitted |

### `EpsPaymentResult`

| Property | Type | Description |
|---|---|---|
| `status` | `EpsPaymentStatus` | `success`, `failed`, `cancelled`, `error` |
| `isSuccess` | `bool` | Convenience getter |
| `merchantTransactionId` | `String?` | Your transaction ID |
| `epsTransactionId` | `String?` | EPS-assigned transaction ID |
| `errorMessage` | `String?` | Error description if applicable |
| `details` | `EpsTransactionStatus?` | Full verification response |

---

## Environments

| Environment | API Base URL |
|---|---|
| `EpsEnvironment.sandbox` | `https://sandboxpgapi.eps.com.bd` |
| `EpsEnvironment.live` | `https://pgapi.eps.com.bd` |

Sandbox credentials are available from the [EPS merchant portal](https://merchant.eps.com.bd).

---

## How It Works

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

---

## License

MIT © [Pritom Chaki](https://github.com/Pritom-Chaki)
