import '../models/payment_event.dart';
import 'package:uuid/uuid.dart';

class PaymentParser {
  static const _uuid = Uuid();

  static PaymentEvent? parse(String sender, String message) {
    final lowerMsg = message.toLowerCase();
    String provider = 'unknown';
    
    if (sender.contains('bkash') || lowerMsg.contains('bkash')) {
      provider = 'bkash';
    } else if (sender.contains('nagad') || lowerMsg.contains('nagad')) {
      provider = 'nagad';
    } else if (sender.contains('rocket') || lowerMsg.contains('rocket')) {
      provider = 'rocket';
    } else {
      // Not a target payment message
      return null;
    }

    double? amount;
    String? trxId;
    String? phone;

    // Regex Examples (Simplified for demo)
    
    // Amount: "Tk 500.00", "Tk 5,000"
    final amountRegex = RegExp(r'Tk\s?([\d,]+\.?\d*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(message);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    }

    // TrxID: "TrxID 8J7...", "TxnId: ..."
    final trxRegex = RegExp(r'(?:TrxID|TxnId|Trans ID)[\s:]*([A-Z0-9]+)', caseSensitive: false);
    final trxMatch = trxRegex.firstMatch(message);
    if (trxMatch != null) {
      trxId = trxMatch.group(1);
    }

    // Phone: "017..." (Sender or Ref)
    final phoneRegex = RegExp(r'(01[3-9]\d{8})');
    final phoneMatch = phoneRegex.firstMatch(message);
    if (phoneMatch != null) {
      phone = phoneMatch.group(1);
    }

    if (amount == null && trxId == null) {
      // Likely not a transactional message
      return null;
    }

    return PaymentEvent(
      id: _uuid.v4(),
      provider: provider,
      rawText: message,
      sender: sender,
      parsedAmount: amount,
      parsedTrx: trxId,
      parsedPhone: phone,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'pending',
    );
  }
}
