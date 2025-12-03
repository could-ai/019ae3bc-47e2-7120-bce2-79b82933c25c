import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart' as fnl;
import 'data/database_helper.dart';
import 'models/payment_event.dart';
import 'services/background_service.dart' as bg;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize WorkManager
  await Workmanager().initialize(
    bg.appCallbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoVerify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Telephony telephony = Telephony.instance;
  List<PaymentEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _requestPermissions();
    _initListeners();
  }

  Future<void> _loadEvents() async {
    final events = await DatabaseHelper.instance.getAllEvents();
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.sms,
      Permission.notification,
    ].request();
  }

  Future<void> _initListeners() async {
    // SMS Listener
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        // Foreground handler
        bg.onSmsReceived(message);
        _loadEvents(); // Refresh UI
      },
      onBackgroundMessage: bg.onSmsReceived,
    );

    // Notification Listener
    try {
      final bool? isPermissionGranted = await fnl.FlutterNotificationListener.isPermissionGranted;
      if (isPermissionGranted != true) {
        // We can't force this, user must enable it manually via settings
        debugPrint("Notification Listener permission not granted");
      } else {
        fnl.FlutterNotificationListener.registerGlobalServiceCallback(bg.onNotificationReceived);
      }
    } catch (e) {
      debugPrint("Error initializing notification listener: $e");
    }
  }

  Future<void> _openNotificationSettings() async {
    await fnl.FlutterNotificationListener.openPermissionSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoVerify Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _openNotificationSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Enable Notification Access'),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return ListTile(
                        leading: Icon(
                          event.provider == 'bkash' ? Icons.payment :
                          event.provider == 'nagad' ? Icons.account_balance_wallet :
                          Icons.message,
                          color: event.status == 'uploaded' ? Colors.green : Colors.orange,
                        ),
                        title: Text('${event.provider.toUpperCase()} - ${event.parsedAmount ?? "N/A"}'),
                        subtitle: Text('Trx: ${event.parsedTrx ?? "N/A"}\n${event.sender}'),
                        trailing: Text(event.status),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
