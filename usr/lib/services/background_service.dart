import 'package:workmanager/workmanager.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:logger/logger.dart';
import '../data/database_helper.dart';
import '../services/api_service.dart';
import '../utils/payment_parser.dart';

const String taskName = 'uploadEventsTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger();
    logger.i('Background task started: $task');

    if (task == taskName) {
      final db = DatabaseHelper.instance;
      final api = ApiService();

      final pendingEvents = await db.getPendingEvents();
      if (pendingEvents.isEmpty) {
        logger.i('No pending events to upload.');
        return true;
      }

      final success = await api.uploadEvents(pendingEvents);
      if (success) {
        await db.markEventsAsUploaded(pendingEvents.map((e) => e.id).toList());
        logger.i('Successfully uploaded ${pendingEvents.length} events.');
      } else {
        logger.w('Failed to upload events. Will retry.');
        return false; // Causes retry
      }
    }
    return true;
  });
}

@pragma('vm:entry-point')
void onSmsReceived(SmsMessage message) async {
  final logger = Logger();
  logger.i('SMS Received: ${message.address} - ${message.body}');
  
  if (message.body == null || message.address == null) return;

  final event = PaymentParser.parse(message.address!, message.body!);
  if (event != null) {
    await DatabaseHelper.instance.insertEvent(event);
    logger.i('Payment Event saved: ${event.parsedTrx}');
    
    // Trigger immediate upload attempt
    Workmanager().registerOneOffTask(
      'immediate_upload_${event.id}',
      taskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

@pragma('vm:entry-point')
void onNotificationReceived(NotificationEvent evt) async {
  final logger = Logger();
  // evt.packageName, evt.title, evt.text
  logger.i('Notification: ${evt.packageName} : ${evt.text}');
  
  if (evt.text == null) return;
  
  // Map package name to sender/provider if possible, or just use package name
  final sender = evt.packageName ?? 'unknown';
  final body = '${evt.title ?? ""} ${evt.text ?? ""}';
  
  final event = PaymentParser.parse(sender, body);
  if (event != null) {
    await DatabaseHelper.instance.insertEvent(event);
    logger.i('Notification Payment Event saved: ${event.parsedTrx}');
    
    Workmanager().registerOneOffTask(
      'immediate_upload_notif_${event.id}',
      taskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
