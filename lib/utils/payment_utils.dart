import 'dart:math';

import 'package:flutter/material.dart';

import '../models/payment_config.dart';
import '../models/payment_result.dart';

class PaymentUtils {
  static String generateTransactionId() {
    var random = Random();
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    var randomNum = random.nextInt(999999);
    return 'TXN$timestamp$randomNum';
  }

  static String buildUPIUrl({
    required PaymentConfig config,
    required String transactionId,
    required String appScheme,
  }) {
    String baseUrl;

    switch (appScheme.toLowerCase()) {
      case 'tez':
        baseUrl = 'tez://upi/pay';
        break;
      case 'phonepe':
        baseUrl = 'phonepe://upi/pay';
        break;
      case 'paytmmp':
        baseUrl = 'paytmmp://upi/pay';
        break;
      case 'amazonpay':
        baseUrl = 'amazonpay://upi/pay';
        break;
      case 'bhim':
        baseUrl = 'bhim://upi/pay';
        break;
      case 'cred':
        baseUrl = 'cred://upi/pay';
        break;
      case 'mobikwik':
        baseUrl = 'mobikwik://upi/pay';
        break;
      case 'freecharge':
        baseUrl = 'freecharge://upi/pay';
        break;
      case 'yonosbi':
        baseUrl = 'yonosbi://upi/pay';
        break;
      default:
        baseUrl = 'upi://pay';
    }

    return '$baseUrl?'
        'pa=${config.receiverUpiId}&'
        'pn=${Uri.encodeComponent(config.receiverName)}&'
        'tid=$transactionId&'
        'tr=$transactionId&'
        'tn=${Uri.encodeComponent(config.transactionNote)}&'
        'am=${config.amount.toStringAsFixed(2)}&'
        'cu=${config.currency}';
  }

  static String buildIOSUPIUrl({
    required PaymentConfig config,
    required String transactionId,
    required String appScheme,
  }) {
    // Updated return URL to match new scheme
    String returnUrl = config.returnUrl ?? 'upipaymentapp://upi';

    String baseUrl;
    switch (appScheme.toLowerCase()) {
      case 'tez':
        baseUrl = 'tez://upi/pay';
        break;
      case 'phonepe':
        baseUrl = 'phonepe://pay';
        break;
      default:
        baseUrl = '$appScheme://upi/pay';
    }

    return '$baseUrl?'
        'pa=${config.receiverUpiId}&'
        'pn=${Uri.encodeComponent(config.receiverName)}&'
        'tid=$transactionId&'
        'tr=$transactionId&'
        'tn=${Uri.encodeComponent(config.transactionNote)}&'
        'am=${config.amount.toStringAsFixed(2)}&'
        'cu=${config.currency}&'
        'url=$returnUrl';
  }

  static String buildWebPaymentUrl(PaymentConfig config) {
    // Updated return URL
    return 'https://razorpay.com/demo/payment?'
        'amount=${(config.amount * 100).toInt()}&' // Convert to paisa
        'name=${Uri.encodeComponent(config.receiverName)}&'
        'description=${Uri.encodeComponent(config.transactionNote)}&'
        'currency=${config.currency}&'
        'return_url=upipaymentapp://upi';
  }

  static PaymentResult parsePaymentResult(
    String status,
    String txnId,
    String response,
  ) {
    String title;
    String message;
    IconData icon;
    Color color;

    switch (status.toUpperCase()) {
      case 'SUCCESS':
        title = 'Payment Successful!';
        message = 'Your payment has been completed successfully.';
        icon = Icons.check_circle;
        color = Colors.green;
        break;

      case 'FAILURE':
        title = 'Payment Failed';
        message = 'Your payment could not be processed. Please try again.';
        icon = Icons.error;
        color = Colors.red;
        break;

      case 'SUBMITTED':
        title = 'Payment Submitted';
        message =
            'Your payment is being processed. You will receive a confirmation shortly.';
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;

      case 'TIMEOUT':
        title = 'Payment Timeout';
        message =
            'The payment took too long to process. Please check your account or try again.';
        icon = Icons.access_time;
        color = Colors.orange;
        break;

      case 'CANCELLED':
        title = 'Payment Cancelled';
        message = 'You cancelled the payment.';
        icon = Icons.cancel;
        color = Colors.grey;
        break;

      default:
        title = 'Unknown Status';
        message = 'Payment status is unknown. Please check your account.';
        icon = Icons.help;
        color = Colors.grey;
    }

    return PaymentResult(
      status: status,
      title: title,
      message: message,
      icon: icon,
      color: color,
      transactionId: txnId,
      rawResponse: response,
    );
  }

  static String formatCurrency(double amount, {String currency = 'INR'}) {
    switch (currency) {
      case 'INR':
        return '₹${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  static bool isValidUPIId(String upiId) {
    // Basic UPI ID validation
    final upiRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$');
    return upiRegex.hasMatch(upiId);
  }

  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 100000; // Max ₹1,00,000
  }

  static String maskUPIId(String upiId) {
    if (upiId.length <= 4) return upiId;

    int atIndex = upiId.indexOf('@');
    if (atIndex == -1) return upiId;

    String username = upiId.substring(0, atIndex);
    String domain = upiId.substring(atIndex);

    if (username.length <= 4) return upiId;

    String maskedUsername =
        username.substring(0, 2) +
        '*' * (username.length - 4) +
        username.substring(username.length - 2);

    return maskedUsername + domain;
  }

  static Duration getPaymentTimeout() {
    return Duration(minutes: 5); // Standard UPI timeout
  }

  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'U01':
        return 'Invalid VPA (UPI ID)';
      case 'U02':
        return 'Invalid amount';
      case 'U03':
        return 'Transaction not permitted';
      case 'U04':
        return 'Insufficient funds';
      case 'U05':
        return 'Authentication failed';
      case 'U06':
        return 'Transaction declined by bank';
      case 'U07':
        return 'Transaction timeout';
      case 'U08':
        return 'Service unavailable';
      case 'U09':
        return 'Daily limit exceeded';
      case 'U10':
        return 'Invalid PIN';
      default:
        return 'Transaction failed. Please try again.';
    }
  }
}
