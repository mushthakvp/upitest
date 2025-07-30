import 'package:flutter/material.dart';

class PaymentResult {
  final String status;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? transactionId;
  final String? rawResponse;

  PaymentResult({
    required this.status,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.transactionId,
    this.rawResponse,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
  bool get isFailure => status.toUpperCase() == 'FAILURE';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isTimeout => status.toUpperCase() == 'TIMEOUT';
}
