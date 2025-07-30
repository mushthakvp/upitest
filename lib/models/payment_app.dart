import 'package:flutter/material.dart';

class PaymentApp {
  final String name;
  final String packageName;
  final String scheme;
  final String icon;
  final Color color;
  final bool isInstalled;
  final bool isSupported;

  PaymentApp({
    required this.name,
    required this.packageName,
    required this.scheme,
    required this.icon,
    required this.color,
    this.isInstalled = false,
    this.isSupported = true,
  });

  PaymentApp copyWith({
    String? name,
    String? packageName,
    String? scheme,
    String? icon,
    Color? color,
    bool? isInstalled,
    bool? isSupported,
  }) {
    return PaymentApp(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      scheme: scheme ?? this.scheme,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isInstalled: isInstalled ?? this.isInstalled,
      isSupported: isSupported ?? this.isSupported,
    );
  }
}
