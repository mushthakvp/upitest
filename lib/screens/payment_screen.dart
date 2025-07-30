import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/payment_app.dart';
import '../models/payment_config.dart';
import '../models/payment_result.dart';
import '../services/payment_service.dart';
import '../utils/payment_utils.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  List<PaymentApp> availableApps = [];
  bool isLoading = true;
  String paymentStatus = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final PaymentConfig config = PaymentConfig(
    receiverUpiId: "merchant@paytm",
    receiverName: "Demo Merchant",
    amount: 100.0,
    transactionNote: "Payment for demo order",
    currency: "INR",
  );

  static const platform = MethodChannel('upi_payment_channel');
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupMethodChannel();
    _loadPaymentApps();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onPaymentResponse') {
        String status = call.arguments['status'] ?? 'FAILURE';
        String txnId = call.arguments['txnId'] ?? '';
        String response = call.arguments['response'] ?? '';

        _handlePaymentResponse(status, txnId, response);
      }
    });
  }

  Future<void> _loadPaymentApps() async {
    try {
      List<PaymentApp> apps = await _paymentService.getAvailablePaymentApps();
      setState(() {
        availableApps = apps;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error', 'Failed to load payment apps: $e');
    }
  }

  Future<void> _initiatePayment(PaymentApp app) async {
    try {
      HapticFeedback.lightImpact();

      String transactionId = PaymentUtils.generateTransactionId();

      if (Platform.isAndroid) {
        await _launchAndroidPayment(app, transactionId);
      } else {
        await _launchIOSPayment(app, transactionId);
      }
    } catch (e) {
      _showErrorDialog('Payment Error', 'Failed to initiate payment: $e');
    }
  }

  Future<void> _launchAndroidPayment(
    PaymentApp app,
    String transactionId,
  ) async {
    String upiUrl = PaymentUtils.buildUPIUrl(
      config: config,
      transactionId: transactionId,
      appScheme: app.scheme,
    );

    Uri uri = Uri.parse(upiUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showPaymentProgressDialog();
    } else {
      _showAppNotInstalledDialog(app);
    }
  }

  Future<void> _launchIOSPayment(PaymentApp app, String transactionId) async {
    if (app.packageName == 'apple.pay') {
      _showApplePayDialog();
      return;
    }

    if (app.packageName == 'web.payment') {
      await _launchWebPayment();
      return;
    }

    // Try to launch iOS UPI app
    try {
      String upiUrl = PaymentUtils.buildIOSUPIUrl(
        config: config,
        transactionId: transactionId,
        appScheme: app.scheme,
      );

      bool launched = await platform.invokeMethod('launchApp', {
        'scheme': upiUrl,
      });

      if (launched) {
        _showPaymentProgressDialog();
      } else {
        _showAppNotInstalledDialog(app);
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to launch ${app.name}: $e');
    }
  }

  Future<void> _launchWebPayment() async {
    String webUrl = PaymentUtils.buildWebPaymentUrl(config);

    try {
      Uri uri = Uri.parse(webUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showPaymentProgressDialog();
      } else {
        _showErrorDialog('Error', 'Cannot open web payment');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to launch web payment: $e');
    }
  }

  void _showPaymentProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            SizedBox(height: 20),
            Text(
              'Processing Payment...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            Text(
              '₹${config.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Please complete the payment in your UPI app',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handlePaymentResponse('CANCELLED', '', '');
              },
              child: Text('Cancel Payment'),
            ),
          ],
        ),
      ),
    );

    // Auto timeout
    Future.delayed(Duration(seconds: 60), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
        _handlePaymentResponse('TIMEOUT', '', '');
      }
    });
  }

  void _handlePaymentResponse(String status, String txnId, String response) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    HapticFeedback.mediumImpact();

    PaymentResult result = PaymentUtils.parsePaymentResult(
      status,
      txnId,
      response,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(result.icon, color: result.color, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text(result.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (txnId.isNotEmpty) ...[
              SizedBox(height: 10),
              Text(
                'Transaction ID: $txnId',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (status.toUpperCase() == 'FAILURE')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry payment logic can be added here
              },
              child: Text('Retry'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (status.toUpperCase() == 'SUCCESS') {
                Navigator.of(context).pop(); // Go back to main screen
              }
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppNotInstalledDialog(PaymentApp app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.orange),
            SizedBox(width: 8),
            Text('App Not Installed'),
          ],
        ),
        content: Text(
          '${app.name} is not installed on your device. Please install it from the ${Platform.isIOS ? "App Store" : "Play Store"} to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppStore(app);
            },
            child: Text('Install App'),
          ),
        ],
      ),
    );
  }

  void _openAppStore(PaymentApp app) async {
    String storeUrl = Platform.isIOS
        ? 'https://apps.apple.com/search?term=${app.name}'
        : 'https://play.google.com/store/apps/details?id=${app.packageName}';

    Uri uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showApplePayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Text('🍎', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Apple Pay'),
          ],
        ),
        content: Text(
          'Apple Pay integration requires additional setup with Apple Developer account and payment processor. This is a demo version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Select Payment Method'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Payment Summary Card
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount:',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        '₹${config.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'To: ${config.receiverName}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'UPI ID: ${config.receiverUpiId}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Note: ${config.transactionNote}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Platform Indicator
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Platform.isIOS ? Colors.grey[100] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Platform.isIOS
                      ? Colors.grey[300]!
                      : Colors.green[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Platform.isIOS ? Icons.phone_iphone : Icons.android,
                    color: Platform.isIOS
                        ? Colors.grey[600]
                        : Colors.green[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Platform.isIOS
                          ? 'iOS Device - Web & Apple Pay Options Available'
                          : 'Android Device - Full UPI Support',
                      style: TextStyle(
                        color: Platform.isIOS
                            ? Colors.grey[600]
                            : Colors.green[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Payment Methods List
            if (isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[600]!,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading payment methods...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else if (availableApps.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No payment methods available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please install a UPI app to continue',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableApps.length,
                  itemBuilder: (context, index) {
                    final app = availableApps[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _initiatePayment(app),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: app.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      app.icon,
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Pay ₹${config.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (!app.isInstalled) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          'Tap to install',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  app.isInstalled
                                      ? Icons.arrow_forward_ios
                                      : Icons.download,
                                  color: app.color,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
