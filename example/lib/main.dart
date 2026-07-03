import 'package:eps_payment_gateway/eps_payment_gateway.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

// ---------------------------------------------------------------------------
// EPS Gateway instance — created once, reused across the app.
// Use EpsEnvironment.sandbox for testing, .live for production.
// On Flutter web, set webAuthEndpoint to your backend proxy URL to avoid CORS.
// ---------------------------------------------------------------------------
final _eps = EpsPaymentGateway(
  config: const EpsConfig(
    merchantId: '29e86e70-0ac6-45eb-ba04-9fcb0aaed12a',
    storeId: 'd44e705f-9e3a-41de-98b1-1674631637da',
    hashKey: 'FHZxyzeps56789gfhg678ygu876o=',
    userName: 'Epsdemo@gmail.com',
    password: 'Epsdemo258@',
    environment: EpsEnvironment.sandbox,
    //webAuthEndpoint: 'https://your-proxy.com/api', // Required on Flutter web
  ),
);

enum _PaymentTab { direct, server }

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
  _PaymentTab _tab = _PaymentTab.direct;
  bool _loading = false;
  EpsPaymentResult? _lastDirectResult;
  PaymentResult? _lastServerResult;
  EpsDisplayMode _mode = EpsDisplayMode.modalBottomSheet;

  // Server-mode fields (backed by text controllers for editability).
  final _initUrlController = TextEditingController(
    text: 'https://pixposbd.com/api/eps/init',
  );
  final _invoiceController = TextEditingController(text: 'INV-001');
  final _amountController = TextEditingController(text: '500');
  final _nameController = TextEditingController(text: 'Rahim Uddin');
  final _phoneController = TextEditingController(text: '01712345678');
  final _emailController = TextEditingController(
    text: 'rahim@example.com',
  );

  @override
  void dispose() {
    _initUrlController.dispose();
    _invoiceController.dispose();
    _amountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Sample order (direct mode) ─────────────────────────────────────────

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

  // ── Direct mode pay ────────────────────────────────────────────────────

  Future<void> _payDirect() async {
    setState(() {
      _loading = true;
      _lastDirectResult = null;
    });

    final result = await _eps.pay(
      context: context,
      order: _order,
      mode: _mode,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        _lastDirectResult = result;
      });
    }
  }

  // ── Server mode pay ────────────────────────────────────────────────────

  Future<void> _payServer() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _lastServerResult = null;
    });

    final result = await EpsPaymentGateway.startPayment(
      context: context,
      mode: EPSMode.server,
      initUrl: _initUrlController.text.trim(),
      requestBody: {
        'invoice_no': _invoiceController.text.trim(),
        'amount': amount,
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'customer_email': _emailController.text.trim(),
      },
      displayMode: _mode,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        _lastServerResult = result;
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPS Payment Demo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab row: Direct / Server
              SegmentedButton<_PaymentTab>(
                segments: [
                  ButtonSegment(
                    value: _PaymentTab.direct,
                    label: const Text('Direct'),
                    icon: const Icon(Icons.flash_on),
                  ),
                  ButtonSegment(
                    value: _PaymentTab.server,
                    label: const Text('Server'),
                    icon: const Icon(Icons.cloud),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 24),

              // Order summary card (shown in both modes)
              if (_tab == _PaymentTab.direct) _OrderCard(order: _order),

              // Server-mode form
              if (_tab == _PaymentTab.server)
                _ServerForm(
                  initUrlController: _initUrlController,
                  invoiceController: _invoiceController,
                  amountController: _amountController,
                  nameController: _nameController,
                  phoneController: _phoneController,
                  emailController: _emailController,
                ),

              const SizedBox(height: 24),

              // Display mode toggle
              _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 24),

              // Pay button
              FilledButton.icon(
                onPressed: _loading
                    ? null
                    : _tab == _PaymentTab.direct
                        ? _payDirect
                        : _payServer,
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
                label: Text(
                  _loading
                      ? 'Processing…'
                      : _tab == _PaymentTab.direct
                          ? 'Pay BDT ${_order.amount.toStringAsFixed(2)}'
                          : 'Pay via Server',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Direct-mode result
              if (_tab == _PaymentTab.direct && _lastDirectResult != null)
                _ResultCard(result: _lastDirectResult!),

              // Server-mode result
              if (_tab == _PaymentTab.server && _lastServerResult != null)
                _ServerResultCard(result: _lastServerResult!),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Server-mode form
// ---------------------------------------------------------------------------

class _ServerForm extends StatelessWidget {
  const _ServerForm({
    required this.initUrlController,
    required this.invoiceController,
    required this.amountController,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
  });

  final TextEditingController initUrlController;
  final TextEditingController invoiceController;
  final TextEditingController amountController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Mode Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 16),
            TextField(
              controller: initUrlController,
              decoration: const InputDecoration(
                labelText: 'Init URL',
                hintText: 'https://pixposbd.com/api/eps/init',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: invoiceController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice No',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
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
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
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
      color: color.withValues(alpha: 0.1),
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

class _ServerResultCard extends StatelessWidget {
  const _ServerResultCard({required this.result});

  final PaymentResult result;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title) = switch (result.status) {
      PaymentStatus.success => (
          Icons.check_circle,
          Colors.green,
          'Payment Successful',
        ),
      PaymentStatus.failed => (
          Icons.cancel,
          Colors.red,
          'Payment Failed',
        ),
      PaymentStatus.cancelled => (
          Icons.cancel_outlined,
          Colors.orange,
          'Payment Cancelled',
        ),
    };

    return Card(
      color: color.withValues(alpha: 0.1),
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
            if (result.transactionId != null) ...[
              const SizedBox(height: 8),
              _Row('Transaction ID', result.transactionId!),
            ],
            if (result.message != null) ...[
              const SizedBox(height: 4),
              Text(
                result.message!,
                style: TextStyle(color: color, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
