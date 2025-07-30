class PaymentConfig {
  final String receiverUpiId;
  final String receiverName;
  final double amount;
  final String transactionNote;
  final String currency;
  final String? merchantCode;
  final String? returnUrl;

  PaymentConfig({
    required this.receiverUpiId,
    required this.receiverName,
    required this.amount,
    required this.transactionNote,
    this.currency = "INR",
    this.merchantCode,
    this.returnUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'receiverUpiId': receiverUpiId,
      'receiverName': receiverName,
      'amount': amount,
      'transactionNote': transactionNote,
      'currency': currency,
      'merchantCode': merchantCode,
      'returnUrl': returnUrl,
    };
  }
}
