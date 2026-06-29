import 'package:eps_payment_gateway/eps_payment_gateway.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

// ---------------------------------------------------------------------------
// EPS Gateway instance — created once, reused across the app.
// Use EpsEnvironment.sandbox for testing, .live for production.
// ---------------------------------------------------------------------------
final _eps = EpsPaymentGateway(
  config: const EpsConfig(
    merchantId: '29e86e70-0ac6-45eb-ba04-9fcb0aaed12a',
    storeId: 'd44e705f-9e3a-41de-98b1-1674631637da',
    hashKey: 'FHZxyzeps56789gfhg678ygu876o=',
    userName: 'Epsdemo@gmail.com',
    password: 'Epsdemo258@',
    environment: EpsEnvironment.sandbox,
  ),
);

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPS Payment Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A6B3A)),
        useMaterial3: true,
      ),
      home: const CheckoutPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Checkout Page
// ---------------------------------------------------------------------------

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = false;
  EpsPaymentResult? _lastResult;
  EpsDisplayMode _mode = EpsDisplayMode.modalBottomSheet;

  // ── Sample order ─────────────────────────────────────────────────────

  static const _order = EpsOrder(
    orderId: 'ORDER-DEMO-001',
    amount: 1.00,
    customerName: 'Rahim Uddin',
    customerEmail: 'rahim@example.com',
    customerPhone: '01712345678',
    customerAddress: 'House 12, Road 5, Uttara',
    customerCity: 'Dhaka',
    customerPostcode: '1230',
    customerCountry: 'BD',
    products: [
      EpsProduct(name: 'Demo Product', quantity: 1, price: 1.00),
    ],
  );

  // ── Pay ───────────────────────────────────────────────────────────────

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _lastResult = null;
    });

    final result = await _eps.pay(
      context: context,
      order: _order,
      mode: _mode,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        _lastResult = result;
      });
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPS Payment Demo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary card
            _OrderCard(order: _order),
            const SizedBox(height: 24),

            // Display mode toggle
            _ModeToggle(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: 24),

            // Pay button
            FilledButton.icon(
              onPressed: _loading ? null : _pay,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.payment),
              label: Text(_loading ? 'Processing…' : 'Pay BDT ${_order.amount.toStringAsFixed(2)}'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Result
            if (_lastResult != null) _ResultCard(result: _lastResult!),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final EpsOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: theme.textTheme.titleMedium),
            const Divider(height: 16),
            _Row('Order ID', order.orderId),
            _Row('Customer', order.customerName),
            _Row('Email', order.customerEmail),
            for (final p in order.products)
              _Row(p.name, 'x${p.quantity}  BDT ${p.price.toStringAsFixed(2)}'),
            const Divider(height: 16),
            _Row(
              'Total',
              'BDT ${order.amount.toStringAsFixed(2)}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final EpsDisplayMode mode;
  final ValueChanged<EpsDisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<EpsDisplayMode>(
      segments: const [
        ButtonSegment(
          value: EpsDisplayMode.modalBottomSheet,
          label: Text('Bottom Sheet'),
          icon: Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: EpsDisplayMode.fullScreen,
          label: Text('Full Screen'),
          icon: Icon(Icons.open_in_full),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final EpsPaymentResult result;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title) = switch (result.status) {
      EpsPaymentStatus.success => (
          Icons.check_circle,
          Colors.green,
          'Payment Successful',
        ),
      EpsPaymentStatus.failed => (
          Icons.cancel,
          Colors.red,
          'Payment Failed',
        ),
      EpsPaymentStatus.cancelled => (
          Icons.cancel_outlined,
          Colors.orange,
          'Payment Cancelled',
        ),
      EpsPaymentStatus.error => (
          Icons.error_outline,
          Colors.red,
          'Error',
        ),
    };

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            if (result.merchantTransactionId != null) ...[
              const SizedBox(height: 8),
              _Row('Merchant TXN', result.merchantTransactionId!),
            ],
            if (result.epsTransactionId != null)
              _Row('EPS TXN', result.epsTransactionId!),
            if (result.details != null) ...[
              _Row('Amount', 'BDT ${result.details!.totalAmount}'),
              _Row('Method', result.details!.financialEntity),
              _Row('Date', result.details!.transactionDate),
            ],
            if (result.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                result.errorMessage!,
                style: TextStyle(color: color, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
