class PaymentInitData {
  PaymentInitData({
    required this.is3DsV2,
    required this.terminalKey,
    required this.paymentId,
    required this.serverTransId,
    required this.threeDsMethod,
    required this.paymentUrl,
  });

  final bool is3DsV2;
  final String terminalKey;
  final String paymentId;
  final String serverTransId;
  final String threeDsMethod;
  final String paymentUrl;

  PaymentInitData.fromJson(Map<String, dynamic> json)
    : is3DsV2 = json['is3DsVersion2'] == true,
      terminalKey = (json['TerminalKey'] ?? '').toString(),
      paymentId = (json['PaymentId'] ?? json['payment_id'] ?? '0').toString(),
      serverTransId = (json['serverTransId'] ?? '').toString(),
      threeDsMethod = (json['ThreeDSMethodURL'] ?? '').toString(),
      paymentUrl = (json['payment_url'] ?? json['paymentUrl'] ?? '').toString();
}

// {
//     "is3DsVersion2": true,
//     "TerminalKey": "1692261610441",
//     "PaymentId": "3841111576",
//     "serverTransId": "ad0d3cb1-6c2c-40b4-acff-d8e82f6d75a0",
//     "ThreeDSMethodURL": "https://3ds-ds1.mirconnect.ru/ma"
// }