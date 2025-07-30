import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/payment_app.dart';

class PaymentService {
  static const platform = MethodChannel('upi_payment_channel');

  static final List<Map<String, dynamic>> _androidApps = [
    {
      'name': 'Google Pay',
      'package': 'com.google.android.apps.nbu.paisa.user',
      'scheme': 'tez',
      'icon': '💳',
      'color': Colors.blue,
    },
    {
      'name': 'PhonePe',
      'package': 'com.phonepe.app',
      'scheme': 'phonepe',
      'icon': '📱',
      'color': Colors.purple,
    },
    {
      'name': 'Paytm',
      'package': 'net.one97.paytm',
      'scheme': 'paytmmp',
      'icon': '💰',
      'color': Colors.indigo,
    },
    {
      'name': 'Amazon Pay',
      'package': 'in.amazon.mShop.android.shopping',
      'scheme': 'amazonpay',
      'icon': '🛒',
      'color': Colors.orange,
    },
    {
      'name': 'BHIM',
      'package': 'in.org.npci.upiapp',
      'scheme': 'bhim',
      'icon': '🏛️',
      'color': Colors.green,
    },
    {
      'name': 'CRED',
      'package': 'com.dreamplug.androidapp',
      'scheme': 'cred',
      'icon': '💎',
      'color': Colors.black,
    },
    {
      'name': 'Mobikwik',
      'package': 'com.mobikwik_new',
      'scheme': 'mobikwik',
      'icon': '🎯',
      'color': Colors.red,
    },
    {
      'name': 'Freecharge',
      'package': 'com.freecharge.android',
      'scheme': 'freecharge',
      'icon': '⚡',
      'color': Colors.teal,
    },
    {
      'name': 'YONO SBI',
      'package': 'com.sbi.lotusintouch',
      'scheme': 'yonosbi',
      'icon': '🏦',
      'color': Colors.blue[800]!,
    },
  ];

  // iOS Payment Apps
  static final List<Map<String, dynamic>> _iosApps = [
    {
      'name': 'Apple Pay',
      'package': 'apple.pay',
      'scheme': 'applepay',
      'icon': '🍎',
      'color': Colors.black,
    },
    {
      'name': 'Google Pay',
      'package': 'com.google.android.apps.nbu.paisa.user',
      'scheme': 'tez',
      'icon': '💳',
      'color': Colors.blue,
    },
    {
      'name': 'Web Payment',
      'package': 'web.payment',
      'scheme': 'https',
      'icon': '🌐',
      'color': Colors.indigo,
    },
    {
      'name': 'PayPal',
      'package': 'com.paypal.ppmobile',
      'scheme': 'paypal',
      'icon': '💙',
      'color': Colors.blue[700]!,
    },
  ];

  Future<List<PaymentApp>> getAvailablePaymentApps() async {
    if (Platform.isAndroid) {
      return await _getAndroidPaymentApps();
    } else if (Platform.isIOS) {
      return await _getIOSPaymentApps();
    }
    return [];
  }

  Future<List<PaymentApp>> _getAndroidPaymentApps() async {
    List<PaymentApp> availableApps = [];
    for (var appInfo in _androidApps) {
      try {
        bool isInstalled = await _checkAndroidAppInstallation(
          appInfo['package'],
        );
        availableApps.add(
          PaymentApp(
            name: appInfo['name'],
            packageName: appInfo['package'],
            scheme: appInfo['scheme'],
            icon: appInfo['icon'],
            color: appInfo['color'],
            isInstalled: isInstalled,
          ),
        );
      } catch (e) {
        debugPrint('Error checking ${appInfo['name']}: $e');
      }
    }
    return availableApps;
  }

  Future<List<PaymentApp>> _getIOSPaymentApps() async {
    List<PaymentApp> availableApps = [];
    for (var appInfo in _iosApps) {
      try {
        bool isInstalled = true;
        if (appInfo['package'] != 'apple.pay' &&
            appInfo['package'] != 'web.payment') {
          isInstalled = await _checkIOSAppInstallation(appInfo['package']);
        }
        availableApps.add(
          PaymentApp(
            name: appInfo['name'],
            packageName: appInfo['package'],
            scheme: appInfo['scheme'],
            icon: appInfo['icon'],
            color: appInfo['color'],
            isInstalled: isInstalled,
          ),
        );
      } catch (e) {
        debugPrint('Error checking ${appInfo['name']}: $e');
      }
    }
    return availableApps;
  }

  Future<bool> _checkAndroidAppInstallation(String packageName) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkIOSAppInstallation(String packageName) async {
    try {
      return await platform.invokeMethod('checkAppInstallation', {
            'packageName': packageName,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> launchApp(String scheme) async {
    try {
      if (Platform.isIOS) {
        return await platform.invokeMethod('launchApp', {'scheme': scheme}) ??
            false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
