/// Full transaction record returned by the EPS verify endpoint.
class EpsTransactionStatus {
  const EpsTransactionStatus({
    required this.merchantTransactionId,
    required this.epsTransactionId,
    required this.status,
    required this.totalAmount,
    required this.transactionDate,
    required this.transactionType,
    required this.financialEntity,
    required this.errorCode,
    required this.errorMessage,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.paymentReference,
  });

  final String merchantTransactionId;
  final String epsTransactionId;
  final String status;
  final String totalAmount;
  final String transactionDate;
  final String transactionType;
  final String financialEntity;
  final String errorCode;
  final String errorMessage;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String paymentReference;

  factory EpsTransactionStatus.fromJson(Map<String, dynamic> json) =>
      EpsTransactionStatus(
        merchantTransactionId: json['MerchantTransactionId'] as String? ?? '',
        epsTransactionId: json['EpsTransactionId'] as String? ?? '',
        status: json['Status'] as String? ?? '',
        totalAmount: json['TotalAmount'] as String? ?? '',
        transactionDate: json['TransactionDate'] as String? ?? '',
        transactionType: json['TransactionType'] as String? ?? '',
        financialEntity: json['FinancialEntity'] as String? ?? '',
        errorCode: json['ErrorCode'] as String? ?? '',
        errorMessage: json['ErrorMessage'] as String? ?? '',
        customerName: json['CustomerName'] as String? ?? '',
        customerEmail: json['CustomerEmail'] as String? ?? '',
        customerPhone: json['CustomerPhone'] as String? ?? '',
        // API spells "Reference" as "Referance" — preserved intentionally.
        paymentReference: json['PaymentReferance'] as String? ?? '',
      );
}
