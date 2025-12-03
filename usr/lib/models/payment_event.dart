class PaymentEvent {
  final String id;
  final String provider;
  final String rawText;
  final String sender;
  final double? parsedAmount;
  final String? parsedTrx;
  final String? parsedPhone;
  final int timestamp;
  final String status; // 'pending', 'uploaded', 'failed'

  PaymentEvent({
    required this.id,
    required this.provider,
    required this.rawText,
    required this.sender,
    this.parsedAmount,
    this.parsedTrx,
    this.parsedPhone,
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'rawText': rawText,
      'sender': sender,
      'parsedAmount': parsedAmount,
      'parsedTrx': parsedTrx,
      'parsedPhone': parsedPhone,
      'timestamp': timestamp,
      'status': status,
    };
  }

  factory PaymentEvent.fromJson(Map<String, dynamic> json) {
    return PaymentEvent(
      id: json['id'],
      provider: json['provider'],
      rawText: json['rawText'],
      sender: json['sender'],
      parsedAmount: json['parsedAmount'] != null ? (json['parsedAmount'] as num).toDouble() : null,
      parsedTrx: json['parsedTrx'],
      parsedPhone: json['parsedPhone'],
      timestamp: json['timestamp'],
      status: json['status'],
    );
  }
}
