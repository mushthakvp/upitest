import 'package:flutter/material.dart';

import 'screens/payment_screen.dart';

void main() {
  runApp(UPIPaymentApp());
}

class UPIPaymentApp extends StatelessWidget {
  const UPIPaymentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPI Payment App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('UPI Payment Demo'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Icon
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payment, size: 60, color: Colors.blue[600]),
              ),

              SizedBox(height: 40),

              // Title
              Text(
                'Secure Payment Gateway',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16),

              // Subtitle
              Text(
                'Fast, secure, and reliable payments\nSupports UPI, Cards, and more',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 60),

              // Payment Card Preview
              Container(
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
                  children: [
                    Text(
                      'Demo Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '₹100.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Payment for demo purchase',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Pay Now Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: Colors.blue.withOpacity(0.4),
                ),
                child: Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              SizedBox(height: 20),

              // Security Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 16, color: Colors.green[600]),
                  SizedBox(width: 8),
                  Text(
                    'Secured by 256-bit SSL encryption',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
